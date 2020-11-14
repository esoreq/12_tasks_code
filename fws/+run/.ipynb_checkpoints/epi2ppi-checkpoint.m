function Betas = epi2ppi(id,modelDir,roiSet)
% takes epi files that corrospond to a univarite spm model and calculates the pairwise roi PPI FSL style 
% example :
% nodesDir = '/group/hampshire_hub/12TASKS/T1';
% modelDir = '/group/hampshire_hub/oldeyal/data/12Tasks/exploratory';
% outDir = '/group/hampshire_hub/12TASKS/Fusion';
% roiSet = 'Schaefer100Parcels.nii.gz';
% id = 1;
% run.epi2ppi(id,nodesDir,modelDir,outDir,nodesId);
fn = c3nl.select('pth',sprintf('%s/STATS/',modelDir),'name','SPM.mat'); % get valid list of files 
subj = strsplit(fn{id},'/');subj = subj{end-1}; % extract subject name 
load(fn{id}); % load subject SPM model 
EPI = c3nl.select('pth',sprintf('%s/POST/%s',modelDir,subj),'name','*.nii.gz'); % find all the EPI files 
sprintf('%s/ROI',modelDir)
roiSet
c3nl.select('pth',sprintf('%s/ROI',modelDir),'name',roiSet,'output','char')

fprintf('Remap ROI to EPI\n');
[ROI,G] = load.vol(c3nl.select('pth',sprintf('%s/ROI',modelDir),'name',roiSet,'output','char'));
ROI = atlas.reLabel(ROI);
% reslice the nodes file node by node to a 4D binary matrix
ROI = apply.interpolator(struct('V',ROI,'G',G),EPI{1},'reslice'); 
ROI = double(convert.label2Dummy(ROI));
load(c3nl.select('pth',sprintf('%s/LOG/%s',modelDir,subj),'name','Data.mat','output','char')); % Load log struct 
TS  = cell(numel(EPI),1); % preallocate cell structure for Bold ROI time-series
roi = reshape(ROI,[],size(ROI,4)); % reshape to a voxel x roi
fprintf('\nExtract timeseries \n');
order = cellfun(@(x) x{2} ,cellfun(@(x) strsplit(x,'-'),Data.fileMapping.fileId,'un',0),'un',0);
FID = cellfun(@(x) x{1} ,cellfun(@(x) strsplit(x,'-'),Data.fileMapping.fileId,'un',0),'un',0);
for epi=EPI'
    fprintf('*');
    [~,task]=fileparts(epi{1}); % extract run name 
    [Y,G] = load.vol(epi{1}); % load run
    ma = std(Y,[],4)>0;
    idx = find(ma); % generate mask 
    %ts = zeros(size(ROI,4),size(Y,4)); % prealocate roi x time matrix
    Y = reshape(Y,[],size(Y,4)); % reshape to a voxel x time
    Ydm = bsxfun(@minus, Y(idx,:), mean(Y(idx,:),1)); % demean
    roim = roi(idx,:); % get masked roi voxels

    tc = (pinv(roim)*Ydm)'; % regress the component onto the data to produce the time series 
    tcdm = bsxfun(@minus, tc, mean(tc)); % demean the time series 
    fid = strsplit(task,'-');
    ix = ismember(order, fid{2}) & ismember(FID, fid{1}(10:end));
    TS{ix} = detrend(tcdm); % remove trend and mean from all time course and map to model order
end
fprintf('\nEstimate PPI\n');
d = size(roi);
[~,ord] = sort(categorical(Data.fileMapping.taskName));
TS = TS(ord);
pc=[nchoosek(1:d(2),2);fliplr(nchoosek(1:d(2),2))];
ix = find(c3nl.strDetect(SPM.xX.name,'constant')); % find runs 
des = SPM.xX.X; % extract design
Cn = SPM.xX.name; % column names
xX = SPM.xX; % design structure
runs = size(ix(:),1);
Betas = [];
for ii = 1:runs
    Fc = struct2table(SPM.Sess(ii).Fc);
    x = xX.X(SPM.Sess(ii).row,SPM.Sess(ii).col);% design matrix of the run
    x = x(:,Fc.i);% remove the error terms and session constant
    y = TS{ii}; % extract the run ts 
    index = find(~all(y));
    if isempty(index);index = 0;end
    E = SPM.Sess(ii).C; % extract the error terms of this run		
    x1 = x./repmat(std(x),size(x,1),1); % zero centre the psychological regressors
    ds = [1,1,size(x1,2),size(x1,2),size(E.C,2)];de = cumsum(ds)+1; % define the start and end of the different parts of the equation
    beta_x3 = NaN(size(y,2),size(y,2),ds(3)); % generate empty adjacency matrices
    for jj=1:length(pc)    % run over all the pairwise comparisons 
        if ~mod(jj,100);fprintf('*');end
        s =  y(:,pc(jj,1)); % source 
        x2 = y(:,pc(jj,2)); % physiological
        x3 = (x1 .* repmat(x2,1,size(x1,2))); % scalar product
        % (demeaned) scalar product of the 
        % (demeaned) task time-course (zero centred) and the 
        % (demeaned) physiological time-course (time-course of activity in the seed region)   
        x3 = bsxfun(@minus, (x3), mean(x3));% mean center
        if (pc(jj,1)~=index && pc(jj,2)~=index)
            tmp = s \ [ones(size(x2)),x1,x2,x3,E.C]; % ols estimate of coefficients 
            beta_x3(pc(jj,1),pc(jj,2),:) = tmp(de(3):de(4)-1);
        end
        Betas(ii).PPI = beta_x3;
        Betas(ii).names = Fc.name;
    end
    fprintf('\n');
end
D = new.folder(subj,modelDir,{'PPI'});
roiname = strsplit(roiSet,'.');
save(sprintf('%s/%s.mat',D.PPI,roiname{1}),'Betas','-v7.3');

end