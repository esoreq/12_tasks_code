function Betas = epi2dFC(id,modelDir,roiSet)
% takes epi files that corrospond to a univarite spm model and calculates the pairwise roi dFC style
% example :
% nodesDir = '/group/hampshire_hub/12TASKS/T1';
% modelDir = '/group/hampshire_hub/oldeyal/data/12Tasks/exploratory';
% outDir = '/group/hampshire_hub/12TASKS/Fusion';
% roiSet = 'Schaefer100Parcels.nii.gz';
% id = 1;
% run.epi2dFC(id,nodesDir,modelDir,outDir,nodesId);
fn = c3nl.select('pth',sprintf('%s/STATS/',modelDir),'name','SPM.mat'); % get valid list of files
subj = strsplit(fn{id},'/');subj = subj{end-1}; % extract subject name
D = new.folder(subj,modelDir,{'dFC'});
[~,name] = fileparts(roiSet);
en = c3nl.select('pth',D.dFC,'name',sprintf('%s.mat',name),'output','char');
if isempty(en)
load(fn{id}); % load subject SPM model
EPI = c3nl.select('pth',sprintf('%s/POST/%s',modelDir,subj),'name','*.nii.gz'); % find all the EPI files
mEPI = c3nl.select('pth',sprintf('%s/PRE/%s/EPI',modelDir,subj),'name','sw*.nii'); % find all the EPI files
C = c3nl.select('pth',sprintf('%s/PRE/%s/EPI',modelDir,subj),'name','c*.nii');
if  isempty(C)
run.spm12.segment(mEPI{1});
end
[C,g] = load.vol(c3nl.select('pth',sprintf('%s/PRE/%s/EPI',modelDir,subj),'name','c*.nii')); % find all the EPI files
fprintf('Remap ROI to EPI\n');
% reslice the nodes file node by node to a 4D binary matrix
ROI = apply.interpolator(c3nl.select('pth',sprintf('%s/ROI/',modelDir),'name',roiSet,'output','char'),EPI{1},'reslice'); 
ROI = convert.label2Dummy(ROI);
load(c3nl.select('pth',sprintf('%s/LOG/%s',modelDir,subj),'name','Data.mat','output','char')); % Load log struct
TS  = cell(numel(EPI),1); % preallocate cell structure for Bold ROI time-series
roi = double(reshape(ROI,[],size(ROI,4))); % reshape to a voxel x roi
fprintf('\nExtract timeseries \n');
ES  = cell(numel(EPI),1); % preallocate cell structure for Bold ROI error terms
% gray matter mask
% white matter mask
% CSF mask
% Whole brain mask
for epi=EPI'
    fprintf('*');
    [~,task]=fileparts(epi{1}); % extract run name
    Y = load.vol(epi{1}); % load run
    ma = std(Y,[],4)>0;idx = find(ma); % generate mask
    %ts = zeros(size(ROI,4),size(Y,4)); % prealocate roi x time matrix
    Y = reshape(Y,[],size(Y,4)); % reshape to a voxel x time
    Ydm = bsxfun(@minus, Y(idx,:), mean(Y(idx,:),1)); % demean
    roim = roi(idx,:); % get masked roi voxels
    tc = (pinv(roim)*Ydm)'; % regress the component onto the data to produce the time series
    tcdm = bsxfun(@minus, tc, mean(tc)); % demean the time series
    TS{ismember(Data.fileMapping.fileId, task(10:end-20))} = detrend(tcdm); % remove trend and mean from all time course and map to model order
    c = [];
    for ii=1:3
        tmp = double(reshape(C{ii},[],1)>0.75);
        c = [c,tmp];
    end
    c(:,4) = sum(c,2)>0;
    tc = (pinv(c(idx,:))*Ydm)';
    tcdm = detrend(bsxfun(@minus, tc, mean(tc))); % demean the time series
    ES{ismember(Data.fileMapping.fileId, task(10:end-20))} =[tcdm,[zeros(1,size(tcdm,2));diff(tcdm)]];
end
fprintf('\nEstimate dFC\n');
d = size(roi);
[~,ord] = sort(categorical(Data.fileMapping.taskName));
TS = TS(ord);
ES = ES(ord);
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
    is = round([SPM.Sess(ii).U.ons]./2);
    ie = min(is+ round([SPM.Sess(ii).U.dur]./2),size(x,1));% make sure end index is not over the scan length
    E = SPM.Sess(ii).C; % extract the error terms of this run
    FIR = zeros(size(x,1),max(ie-is)); % create the FIR structure for each of the blocks
    for k=1:numel(is)
        w = ie(k)-is(k);
        FIR(is(k)+1:ie(k),1:w) = eye(w);
    end
    % construct the design matrix and regress out the activation using FIR and the nuisance regressors
    resid = y;
    x = [ones(length(FIR),1) FIR E.C ES{ii}];
    for jj=1:size(y,2)
         b = y(:,jj) \ x;
        %b = regress(y(:,jj), x); % is more senstive when Matrix is close to singular
        Yhat = x*b';
        resid(:,jj) = y(:,jj) - Yhat;
    end
    Beta = NaN(size(y,2),size(y,2),numel(is)); % generate empty adjacency matrices
    for k=1:numel(is) % for each block
        Beta(:,:,k) =corrcoef(resid(is(k):ie(k),:));
    end
    Betas(ii).dFC = Beta;
    Betas(ii).names = Fc.name;
end
fprintf('\n');
save(sprintf('%s/%s.mat',D.dFC,name),'Betas','-v7.3');
else 

fprintf('\n%s %s exist\n',subj,name);


end
end