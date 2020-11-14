
clear;clc;close all
addpath /Users/eyalsoreq/GoogleDrive/Projects/OnGoing/Fusion-Watershed/src/matlab-fws

cd /Users/eyalsoreq/GoogleDrive/Projects/OnGoing/12Tasks/Analysis/
D = new.folder([],pwd,{'Report','Data','Figures','Tables'});

%% deal with differences in label order data
hfs = categorical({'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'});
order = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};


%% Load psychometric distance from factor analysis to define Task order across figures
load(fws.select('pth',fws.select('pth','./Data','name','Factors','output','char'),'name','*.mat','output','char'));
factor.ShortID = order([3,1,9,2,11,10,6,4,7,8,12,5])';
[~,ix] = ismember(order,factor.ShortID);
factor = factor(ix,:);

% imagesc(1:12)
% colormap(cmap)

% Generate maximum intenstiy projection in axial view
if ~exist('im','var')
    fn = sort(fws.select('pth','./Data','name','spm*'));
    [~,ix] = ismember(order,factor.ShortID);
    im = [];
    cmap = turbomap(16);
    cmap([9,12,14,15],:)=[];
    %cmap = turbomap(12);
    for ii=1:numel(fn)
        [Y,G] = load.vol(fn{fws.strDetect(fn,factor.TaskId{ii})});
        n=order{ii};
        if ~isfield(im,n)
            tmap=fws.cmap2tone(cmap(ii,:),[0.1,0.5,0.8,1],100,2);
            %tmap=c3nl.cmap([cmap(ii,:).^20;cmap(ii,:);cmap(ii,:).^.01],100);
            im.(n) = plot.mip(Y,G,'plane','a','color',tmap);
        end
    end
end


fn = fws.select('pth','./Data/ROIs','name','CT_200.nii');
[L,G] = load.vol(fn{1});
T = fws.label_to_table('label',L,'grid',G);
load('/Users/eyalsoreq/GoogleDrive/Projects/OnGoing/12Tasks/Analysis/Data/Metrics/FIR/CT_200.mat')
Xg = grpstats(table(X,Y,'VariableNames',{'xx','Y'}),{'Y'},{'mean','median','std'},'DataVars','xx');




n = height(T);
adj = [] ;

for ii=1:12
    name=order{ii};
    ix = fws.strDetect(cellstr(Xg.Y),factor.TaskId{ii});
    w = Xg.mean_xx(ix,:)-mean(Xg.mean_xx);
    tmp = zeros(n);
    tmp(triu(true(n),1)) = w;
    adj.(name) = [];
    adj.(name).M = fws.sym_adj(tmp,'upper');
    adj.(name).cmap = fws.cmap2tone(cmap(ii,:),[0.1,0.5,0.8,1],100,2);
end





T.cid = T.id_Yeo7;
[~,ix] = sort(T.cid);
hf=figure(1);clf
hf.Position = [200,200,700,700];% half resolution for display
p = panel(hf);
sz = [4,3];
p.pack(3,4);
p.margin = [0,0,0,0];% left, bottom right  top
for ii=1:12
    [col,row] = ind2sub(sz,ii);
    q = p(row,col).select();
    axis(q,'off');
    ax = axes('Position',q.Position);
    M =  adj.(order{ii}).M(ix,ix);
    imagesc(ax,M)
    axis(ax,'off');
    ax.CLim = [-.25,.25];
    colormap(ax,adj.(order{ii}).cmap.^.65)
    pos = q.Position.*[1,1,0.85,0.85];
    shift = q.Position.*[1,1,0.075,0.075];
    ax2 = axes('Position',pos+[shift(3),shift(4),0,0]);
    plot.mip_blend(ax2,im.(order{ii}));%activation maps
end

save.pdf(sprintf('%s/cover_new.ai',D.Figures),14,14)



