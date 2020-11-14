%% figure 6 revisited 

% 1st column
% scatter plots of leave one out classification perfomance vs behavioural
% perfomance index acros ROI sets
% 2st column
% Schemable of sparse CRTX classification results 
% 3st column
% Mean RSN values and ensamble models 
% 4st column
% Ensamble trees 


clear;clc;close all
path = fileparts(matlab.desktop.editor.getActiveFilename);
cd (path)
addpath ../fws
cd ..
D = new.folder([],pwd,{'Data','Figures','Tables'});

% load data 
origOrder = {'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'};
newOrder = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};
load(fws.select('pth',D.Data,'name','factors.mat','output','char'));

psychometricDistance = factor{:,4:end};

load(fws.select('name','INDDiff.mat','output','char'));
load(fws.select('name','IndividualDiff.mat','output','char'));

% Calculate g' per participant
scores= table2array(tF(:,2:end));
[~,ix]= ismember(factor.TaskId,tF.Properties.VariableNames(2:end));
sc = fws.scale(scores(:,ix),'mn',0,'mx',1,'method','col');
[Lambda,Psi,T,stats,g] = factoran(sc(:,ix),1,'rotate','none','scores','regression');
[r,p]= corr(sc,g);
IndividualDiff.Subj= categorical(cellstr(char(IndividualDiff.Subj)));
IndividualDiff = sortrows(IndividualDiff,{'set','Subj',});
% Calculate accumalated accuarcy per subject ' per participant
IndividualDiff = [IndividualDiff,array2table(IndividualDiff{:,4:end}==IndividualDiff.Y,'VariableNames',cellfun(@(x) ['Acc_' x] ,IndividualDiff.Properties.VariableNames(4:end),'un',0))];
sets_o = unique(IndividualDiff.set)';
sets_r = {'CRTX','MDDM','INTR'};
IndividualDiff.set = categorical(IndividualDiff.set,sets_o,sets_r);
ds = grpstats(IndividualDiff,{'Subj','set'},{'mean'},'DataVars',IndividualDiff.Properties.VariableNames(7:end));
fn = fws.select('pth','./Data/ROIs','name','CT_200.nii');
[L,G] = load.vol(fn{1});
T = fws.label_to_table('label',L,'grid',G);
fn = fws.select('pth','./Data/ML_results','name','INDI_lasso_models.mat');
load(fn{1})

A = zeros(12,19900,60);
for ii=1:size(models,1)
   A(:,:,ii) = cell2mat(models{ii,1}');
end

%

cmap{1} = [76,29,50;212,32,39;226,127,101;156,156,156]./256;
cmap{2} = [20,84,81;158,207,126;65,153,69;156,156,156]./256;
cmap{3} = [93,62,40;251,174,35;244,136,35;156,156,156]./256;
cmap{4} = [251,174,35]./256;

%%


lg2 = [0.05,0.20,-1.6,-2.1];
lg1 = [0.05,0.20,-1.6,-2.1];
letters = arrayfun(@(x) sprintf('%s.',char(x)), (1:9)+96,'un',0);

hf=figure(5);
clf
p = panel(hf);
[~,ix_f1order] = ismember(newOrder,origOrder);
ix = dummyvar(ds.set)>0;

dss = [ds{ix(:,1),4:end},ds{ix(:,2),4:end},ds{ix(:,3),4:end}];
[~,~,~,outliers] = robustcov(dss,'Method','FMCD','OutlierFraction',0.01);
% make table for supp
idx = outliers;
outDS = grpstats(IndividualDiff,{'Subj','set'},{'mean'},'DataVars',IndividualDiff.Properties.VariableNames(7:end));
outDS{:,4:end} = min(max(round(outDS{:,4:end}*100,1),0),100);
ix = dummyvar(outDS.set)>0;
out_DS =table(outDS{ix(:,1),1},outDS{ix(:,1),3},outDS{ix(:,1),4},outDS{ix(:,1),5},outDS{ix(:,1),6},outDS{ix(:,2),4},outDS{ix(:,2),5},outDS{ix(:,2),6},outDS{ix(:,3),4},outDS{ix(:,3),5},outDS{ix(:,3),6},categorical(outliers));
out_DS.Properties.VariableNames = {'Subject','Events',...
                                   'BA_{CRTX}','dFC_{CRTX}','Stack_{CRTX}',...
                                   'BA_{MDDM}','dFC_{MDDM}','Stack_{MDDM}',...
                                   'BA_{INTR}','dFC_{INTR}','Stack_{INTR}','Outlier'};
save.table(out_DS,sprintf('%s/Outlier.tex',D.Tables),'latex','cap','t02')
% Define rows proportion
p.pack('h',repmat({1/4},1,4));
p.margin = [10,5,2,5];% right bottom left  top
indmet = {'BA','dFC','Stack'};
Metrics = {'BA','dFC','Stack'};
k=1;
p(1).pack('v',{0.33,0.33,0.33})
for m={'INTR','MDDM','CRTX'}
    ix = ds.set == m{1};
    ind_v = ds(ix,[1,4:end]);
    q = p(1,k).select();
    b= q.Position;
    axis(q,'off')
    ax = axes('Position',b);
    plot.group_scatter_fit(ax,g(~idx),ind_v{~idx,2:end},indmet,cmap{k},[-2.2,2.2,0,1.01],'Performance index','Acc',[0,1],lg2,[-2.125,0,4,0.25],'right',2,5);
    text(q,0.425,0.96,m{1},'HorizontalAlignment','center','FontWeight','bold','FontSize',6)
    k=k+1;
end

p(2).pack('v',{0.5,0.5})
T.cat = categorical(T.name_Yeo7);
T.cid = grp2idx(T.cat);
%[cid,ix] = sort(T.cid );
pp = 0.999;
An = mean(mean(A<0,3),1);
Ap = mean(mean(A>0,3),1);
An(An<quantile(An(:),pp))=0;
Ap(Ap<quantile(Ap(:),pp))=0;
AP = zeros(height(T));
AN = zeros(height(T));
ix = find(triu(true(height(T)),1));
AP(ix)=Ap;
AN(ix)=An;
AP = fws.sym_adj(AP,'upper');
AN = fws.sym_adj(AN,'upper');
idl = arrayfun(@(a,b) sprintf(' ',a),T.cat,'un',0);
q = p(2,1).select();
b = q.Position;
axis (q,'off');

ax = axes('Position',[b(1)-b(3)*0.1,b(2),b(3)*1.1,b(4)]);
plot.schemaball(ax,AP,'mode','minimal',"groups",T.cat,...
    "group_color",parula(8),"plot_group_labels",true,...
    "group_labels",["DM","DA","FP","LIM","SM","VA","VS"],...
    "node_size",[0.02,0.1],"link_width",[0.2,4],"lim",[0.3,0.7],...
    "link_color",[0.25,0.25,0.25],"link_alpha",[0.3,0.6],"clim",[0.3,0.7],...
    "colorbar",false,"font_size",6,'node_line_width',0.5)



q = p(2,2).select();
b = q.Position;
axis (q,'off');
ax = axes('Position',[b(1)-b(3)*0.1,b(2)+b(4)*0.05,b(3)*1.1,b(4)]);
plot.schemaball(ax,AN,'mode','minimal',"groups",T.cat,...
    "group_color",parula(8),"plot_group_labels",true,...
    "group_labels",["DM","DA","FP","LIM","SM","VA","VS"],...
    "node_size",[0.02,0.1],"link_width",[0.2,4],"lim",[0.3,0.7],...
    "link_color",[0.25,0.25,0.25],"link_alpha",[0.3,0.6],"clim",[0.3,0.7],...
    "colorbar",false,"font_size",6,'node_line_width',0.5)

%cla(ax)

load('/Users/eyalsoreq/GoogleDrive/Projects/OnGoing/12Tasks/Analysis/Data/Metrics/FIR/CT_200.mat')

Full_Xg = grpstats(table(X,S,'VariableNames',{'xx','S'}),{'S'},{'mean','std'},'DataVars','xx');

rsn = {'Default','Dorsal Attention','Frontoparietal','Limbic','Somatomotor','Ventral Attention','Visual'};
rsn_id = {'DM','DA','FP','LI','SM','VA','VS'};

T.cat = categorical(T.name_Yeo7,rsn,rsn_id);
T.cid = grp2idx(T.cat);

[MU,~,~,tmap,AB,ix2,GROUPS,ab,M] = fws.group_adj( Full_Xg.mean_xx,Full_Xg.S,200,T,parula(8));
xx  = MU';
GROUPS = categorical(GROUPS,cellstr(GROUPS),cellstr(GROUPS));
t = templateTree('MaxNumSplits',3);
gp = cellfun(@(x) strrep(x,' ' ,'_'),categories(GROUPS),'un',0);
mdl = fitrensemble(xx,g,'Learners',t,'NumLearningCycles',3,'PredictorNames',gp,'CrossVal','on','Leaveout','on');

g_hat = mdl.kfoldPredict;
corr(g_hat(~idx),g(~idx));
p(3).pack('v',{0.33,0.33,0.33})
q = p(3,1).select();
gp = cellfun(@(x) strrep(x,' ' ,''),categories(GROUPS),'un',0);
k=k+1;
b = q.Position;
axis (q,'off');
ax = axes('Position',[b(1),b(2),b(3)*0.95,b(4)*0.9]);
rec = zeros(4,numel(unique(ab))-1);
mu = mean(MU');
for ii=1:numel(unique(ab))-1
   tmp = ab==ii;
   ix_x = find(max(tmp,[],1));
   ix_y = find(max(tmp,[],2));
   labels{ii} = sprintf('%s',gp{ii});
   mu_labels{ii} = sprintf('%.2f',mu(ii));
   rec(:,ii) = [min(ix_x),min(ix_y),1,1];
end
plot.rectangles(ax,rec,labels,tmap,0.05);
ax.YDir = 'reverse';


q = p(3,2).select();
b = q.Position;
axis (q,'off');
ax = axes('Position',[b(1),b(2),b(3)*0.95,b(4)*0.9]);


vmap = fws.value_to_cmap(gray,mu);
plot.rectangles(ax,rec,mu_labels,vmap,0.05)
ax.YDir = 'reverse';


q = p(3,3).select();
b= q.Position;
axis(q,'off')
ax = axes('Position',[b(1)-b(3)*0.1,b(2),b(3)*1.2,b(4)]);
%ax = axes('Position',b);
k=k+1;
P = plot.group_scatter_fit(ax,g(~idx),g_hat(~idx),{'RSN'},cmap{3}(3,:).^5,[-2.2,2.2,-2.2,2.2],'Performance index','Predicted PI',[],[ -1.7    -1.7   -0.9000   -1.3000],[-1.4,-2,3.5,0.55],'right',2,5);
text(q,0.4,0.9,'mean RSN dFC','HorizontalAlignment','center','FontWeight','bold','FontSize',6);
%
p(4).pack('v',{0.32,0.36,0.32 })
mdl = fitrensemble(xx,g,'Learners',t,'NumLearningCycles',3,'PredictorNames',gp);
for ii=1:3
    q = p(4,ii).select();
    plot.decision_tree(q,mdl.Trained{ii},0.2,0.1,tmap,[1,4])
end
k=k+1;

b = p.position;
q = axes('Position',b);

text(q,0,0.99,letters{1},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0,0.62,letters{2},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0,0.29,letters{3},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.25,0.99,letters{4},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.505,0.99,letters{5},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.505,0.29,letters{6},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.74,0.99,letters{7},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
axis(q,'off')

%%
save.pdf(sprintf('%s/Fig_6_new.ai',D.Figures),18,10)
