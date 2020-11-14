%% figure 4 revisited 

% 1st column
% scatter plots of classification perfomance
% 2st column
% radar plots of f1-micro performance
% 3st column
% one-vs-one F1 classification perfomance vs psychometric distnace


clear;clc;close all
path = fileparts(matlab.desktop.editor.getActiveFilename);
cd (path)
addpath ../fws
cd ..
D = new.folder([],pwd,{'Data','Figures','Tables'});


%%
pref_12way = load(fws.select('name','DS_12way.mat','output','char'));
pref_2way = load(fws.select('name','DS_2way.mat','output','char'));

load(fws.select('pth','./Data/Metrics/BA','name','intersectionROI.mat','output','char'));
Y = categorical(Y);% all response vectors are the same
origOrder = {'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'};
newOrder = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};
y = categories(Y);
Y = categorical(Y,y,origOrder);%change names to publication version
Yo = categorical(Y,newOrder); % force order 
clear Y X S
load(fws.select('pth',D.Data,'name','factors.mat','output','char'));

psychometricDistance = factor{:,4:end};
simPsyc = exp(-squareform(pdist(psychometricDistance)).^2);


pc = nchoosek(1:numel(y),2);
tp = [y(pc(:,1)),y(pc(:,2))];%task pairs
% ROI plots

%letters = arrayfun(@(x) sprintf('%s.',char(x)), 97:97+11,'un',0);
letters = {'a.','d.','g.','j.','b.','e.','h.','k.','c.','f.','i.','l.'};
metrics = {'BA','dFC','Stack'};

sets_o = unique(pref_12way.DS_12way.set)';
sets_r = {'CRTX','MDDM','INTR'};
pref_12way.DS_12way.name = categorical(pref_12way.DS_12way.set,sets_o,sets_r);
sets_o = unique(pref_2way.DS_2way.set)';
pref_2way.DS_2way.set = categorical(pref_2way.DS_2way.set,sets_o,sets_r);

%% calc individual diff
load(fws.select('name','INDDiff.mat','output','char'));
load(fws.select('name','IndividualDiff.mat','output','char'));


% Calculate g' per participant
scores= table2array(tF(:,2:end));
[~,ix]= ismember(factor.TaskId,tF.Properties.VariableNames(2:end));
sc = fws.scale(scores(:,ix),'mn',0,'mx',1,'method','col');
[~,ix] = ismember(newOrder,factor.ShortID);
factor_sorted = factor(ix,:);
[Lambda,Psi,T,stats,g] = factoran(sc(:,ix),1,'rotate','none','scores','regression');

[r,p]= corr(sc,g);
% Calculate accumalated accuarcy per subject ' per participant
IndividualDiff = [IndividualDiff,array2table(IndividualDiff{:,4:end}==IndividualDiff.Y,'VariableNames',cellfun(@(x) ['Acc_' x] ,IndividualDiff.Properties.VariableNames(4:end),'un',0))];
sets_o = unique(IndividualDiff.set)';
sets_r = {'CRTX','DMMD','INTR'};
IndividualDiff.set = categorical(IndividualDiff.set,sets_o,sets_r);


ds = grpstats(IndividualDiff,{'Subj','set'},{'mean'},'DataVars',IndividualDiff.Properties.VariableNames(7:end));
dst = grpstats(IndividualDiff,{'Y','set'},{'mean'},'DataVars',IndividualDiff.Properties.VariableNames(7:end));
dst = sortrows(dst,'set');
dst_crtx = dst(dst.set=='CRTX',:);
[~,ix] = ismember(factor_sorted.TaskId,dst_crtx.Y);
dst_crtx = dst_crtx(ix,:);

%%

% q1. is cross-validation better than test set regardless of brain set in BA
tmp = grpstats(pref_12way.DS_12way,{'Model_id','Seed'},'mean','DataVars','F1');
ix = fws.strDetect(tmp.Model_id,'BAvx');
tmp = tmp(ix,:);
gp_mdl = categorical(tmp.Model_id,unique(tmp.Model_id),{'BA','Null'});
gp_pref = categorical([tmp.GroupCount.^0;(tmp.GroupCount.^0+1)],1:2,{'CV','Test'});
tmp = table([gp_mdl;gp_mdl],gp_pref,[tmp.mean_F1(:,1);tmp.mean_F1(:,2)],'VariableNames',{'Model','PerformanceType','F1'});
ix = tmp.Model=='Null';
mdl = fitlme(tmp,'F1 ~ 1+Model*PerformanceType');
% grpstats(tmp,{'Model','PerformanceType'},{'mean','std'})
% q2. is there a differnece for including domain specific areas 

tmp = grpstats(pref_12way.DS_12way,{'Model_id','Seed','set'},'mean','DataVars','F1');
tmp = tmp(fws.strDetect(tmp.Model_id,'BAvx'),:);
gp_set = categorical(tmp.set,unique(tmp.set),{'CRTX','MDDM', 'INTR'});
gp_mdl = categorical(tmp.Model_id,unique(tmp.Model_id),{'BA','Null'});
tmp = table(gp_mdl,gp_set,tmp.mean_F1(:,2),'VariableNames',{'Model','Set','F1'});
ix = tmp.Model=='Null';
[p,tbl,stats] = anova1(tmp.F1(~ix),tmp.Set(~ix));
multcompare(stats)

tmp = grpstats(pref_12way.DS_12way,{'Model_id','Seed'},'mean','DataVars','F1');
tmp = tmp(fws.strDetect(tmp.Model_id,'dFC|BAvx'),:);
tmp = tmp(~fws.strDetect(tmp.Model_id,'null'),:);
gp_mdl = categorical(tmp.Model_id,unique(tmp.Model_id),{'BA','dFC'});
tmp = table(tmp.mean_F1(:,2),gp_mdl,tmp.Seed,'VariableNames',{'F1','Model','Seed'});
mdl = fitlme(tmp,'F1 ~ 1+Model+(1|Seed)');


tmp = grpstats(pref_12way.DS_12way,{'Model_id','set','Seed'},'mean','DataVars','F1');
tmp = tmp(fws.strDetect(tmp.Model_id,'dFC'),:);
tmp = tmp(~fws.strDetect(tmp.Model_id,'null'),:);
gp_set = categorical(tmp.set,unique(tmp.set),{'CRTX','MDDM', 'INTR'});

tmp = table(tmp.mean_F1(:,2),gp_set,tmp.Seed,'VariableNames',{'F1','Set','Seed'});
mdl = fitlme(tmp,'F1 ~ 1+Set+(1|Seed)');
[p,tbl,stats] =anova1(tmp.F1,tmp.Set);
multcompare(stats)

tmp = grpstats(pref_12way.DS_12way,{'Model_id','set','Seed'},'mean','DataVars','F1');
gp_set = categorical(tmp.set,unique(tmp.set),{'CRTX','MDDM', 'INTR'});
summPerf = grpstats(table(tmp.Model_id,gp_set,tmp.mean_F1(:,2),'VariableNames',{'Model','Set','F1'}),{'Model','Set'},{'mean','std','meanci'},'DataVars','F1');
summPerf(:,3)=[];
save.table(summPerf(~fws.strDetect(summPerf.Model,'null'),:),sprintf('%s/summPerf.tex',D.Tables),'latex','cap','t02')

summPerf = grpstats(table(tmp.Model_id,gp_set,tmp.mean_F1(:,1),'VariableNames',{'Model','Set','F1'}),{'Model','Set'},{'mean','std','meanci'},'DataVars','F1');
summPerf(:,3)=[];
save.table(summPerf(~fws.strDetect(summPerf.Model,'null'),:),sprintf('%s/CVsummPerf.tex',D.Tables),'latex','cap','t02')


ind = [ds{ds.set=='CRTX',4:end},ds{ds.set=='DMMD',4:end},ds{ds.set=='INTR',4:end}];
[r,p]=corr(ind,g,'type','spearman','tail','right');
pc = fws.fdr(p,1,0.05);
[~,ix_f1order] = ismember(newOrder,origOrder);
tmp = grpstats(pref_12way.DS_12way,{'Model_id','set','Seed'},'mean','DataVars','f1');
gp_set = categorical(tmp.set,unique(tmp.set),{'CRTX','MDDM', 'INTR'});
summPerf = grpstats([table(tmp.Model_id,gp_set,'VariableNames',{'Model','Set'}),array2table(tmp.mean_f1(:,ix_f1order),'VariableNames',newOrder)],{'Model','Set'},{'mean'},'DataVars',newOrder);
summPerf(:,3)=[];
save.table(summPerf(~fws.strDetect(summPerf.Model,'null'),:),sprintf('%s/f1microsummPerf.tex',D.Tables),'latex','cap','t02')

close all
%%

letters = arrayfun(@(x) sprintf('%s.',char(x)), (1:9)+96,'un',0);

cmap{1} = [76,29,50;212,32,39;226,127,101;156,156,156]./256;
cmap{2} = [20,84,81;158,207,126;65,153,69;156,156,156]./256;
cmap{3} = [93,62,40;251,174,35;244,136,35;156,156,156]./256;

hf=figure(5);
clf
p = panel(hf);
[~,ix_f1order] = ismember(newOrder,origOrder);
p.units = 'cm';
p.fontsize=6;

% Define rows proportion
p.pack('v',{0.33,0.33,0.33 0.01});
p.margin = [0.5,0.5,0.5,0.5];% right bottom left  top
indmet = {'BAvx','dFC','Stack'};
Metrics = {'BA','dFC','Stack'};
ix1 = tril(true(12),-1);
k=1;
for m=1:3
    p(m).pack('h',{0.01 0.3,0.3,0.3})
    tmp1 = pref_12way.DS_12way;ix = fws.strDetect(tmp1.Model_id,indmet{m});
    tmp1 = tmp1(ix,:);
    tmp2 = pref_2way.DS_2way;ix = fws.strDetect(tmp2.Model_id,indmet{m});
    tmp2 = tmp2(ix,:);
    ix = find(fws.strDetect(ds.Properties.VariableNames,indmet{m}));
    ind_v = unstack(ds(:,[1,2,ix]),ds.Properties.VariableNames{ix},'set');
    cv = tmp1.F1(:,1);% cross validation estimate
    ho = tmp1.F1(:,2);% hold out estimate
    gp = tmp1.name; % get set groups
    gp(fws.strDetect(tmp1.Model_id,'null'))= categorical({'Null'});%define all nulls as Null
    
    tmp2.set(fws.strDetect(tmp2.Model_id,'null'))= categorical({'Null'});%
    tt = grpstats(tmp2,{'set','Iter','Model_id'},{'mean','std'},'DataVars','F1');
    ix = find(tril(true(12),-1));
    tmp_m = zeros(12,12,4);
    tmp_s = zeros(12,12,4);
    GP  =unique(gp)';
    hfs = {'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'};
    [~,ix_t] = ismember(newOrder,hfs);
    yy = [];ss=[];
    for ii=1:numel(GP)
        tmp = zeros(12);
        tmp(ix) = tt.mean_F1(tt.set==GP(ii));
        tmp = fws.sym_adj(tmp,'lower');
        tmp = tmp(ix_t,ix_t);
        yy(:,ii) = tmp(ix);
        tmp_m(:,:,ii) = tmp;
        tmp(ix) = tt.std_F1(tt.set==GP(ii));
        tmp = fws.sym_adj(tmp,'lower');
        tmp = tmp(ix_t,ix_t);
        ss(:,ii) = tmp(ix);
        tmp_s(:,:,ii)= tmp;
    end
    %[ylim_bottom,ylim_top,x_text,x_marker]      
    if m<3;lg = [0.08,0.35,20,10];else;lg = [0.08,0.25,20,10];end
    if m<3;lg1 = [55,69,0.37,0.28];else;lg1 = [53,63,0.37,0.28];end
    lg2 = [-0.20,0.02,-1.6,-2.1];
    for ii=2:4
        q = p(m,ii).select();
        q.FontSize = 6;

        switch ii
       
            case 2
                ax = plot.scatter_histogram(q,ho,cv,gp,cmap{m},[0,100],{ 'Hold Out','Cross Validation'},lg,indmet{m},5);
                text(ax,5,90,Metrics{m},'HorizontalAlignment','left','FontWeight','bold','FontSize',7);
            case 3
                b= q.Position;
                axis(q,'off')
                ax = axes('Position',[b(1)+0.05*b(3),b(2)+0.1*b(4),b(3)*0.8,b(4)*0.8]);
                plot.radar(ax,tmp1.f1r(:,ix_f1order),gp,[0,100],newOrder,1.1,cmap{m},6);
            case 4
                b= q.Position;
                axis(q,'off')
                ax = axes('Position',b);
                plot.group_scatter_fit(ax,simPsyc(ix),yy,GP,cmap{m},[0.25,1,50,100],'Psychometric Similarity','F1-score',[],lg1,[],'left',2,5);%

        end
        ax.FontSize =6;
        text(q,-0.1,1.05,letters{k},'HorizontalAlignment','left','FontWeight','bold','FontSize',9)
        k=k+1;

    end
end
%%
save.pdf(sprintf('%s/Fig_4_new.ai',D.Figures),13,9)
