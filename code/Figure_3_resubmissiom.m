%% figure 3 revisited 

% 1st panel
% ROi maps for all three sets
% 2st panel
% top panel violin plot of global activation
% Bottom - per task histograms
% 3st panel
% 3 heat maps of correlation
% 4st panel
% 3 scree plots per set


clear;clc;close all
path = fileparts(matlab.desktop.editor.getActiveFilename);
cd (path)
addpath ../fws
cd ..
D = new.folder([],pwd,{'Data','Figures','Tables'});

%% deal with differences in label order data 
hfs = categorical({'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'});
order = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};
[~,ix] = ismember(order,cellstr(char(hfs)));


%% Load group activation volumes
fn = sort(fws.select('pth','./Data','name','spm*'));
for ii=1:numel(fn)
[Y{ii},G{ii}] = load.vol(fn{ii});
end
im = [];
Yo = Y(ix);
rmap = flipud([218,126,100;167,30,39;122,33,90]./256);



%% calculate dice coeficent 

QS = @(a,b) 2*(nnz(a&b))/(nnz(a)+nnz(b));
ix = find(ones(12));
diceMatrix = zeros(12);
for id=ix'
[I,J] = ind2sub([12,12],id);
a = Yo{I};
b = Yo{J};
a(isnan(a))=0;b(isnan(b))=0;
diceMatrix(I,J) =  QS(a,b);
end
clear Yo

%% load voxel-wise activation per ROI set and calculate BA_mag_Similarity
fn = fws.select('pth','./Data/Metrics/BA','name','*.mat');
Sets = {'CRTX','MDDM','INTR'};
for ii=1:numel(Sets)
    XX.(Sets{ii}) = load(fn{ii});
end
order = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};
tmp = XX.INTR;
Y = categorical(tmp.Y);% all response vectors are the same
Y = categorical(Y,categories(Y),{'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'});%change names to publication version
Yo = categorical(Y,order); % force order 
clear Y tmp

ix = tril(true(12),-1);
yy = [];
for s = {'INTR','MDDM','CRTX'}
   XX.(s{1}).Yo  = Yo;
   ds = table(categorical(XX.(s{1}).S),XX.(s{1}).Yo,XX.(s{1}).X, 'VariableNames',{'S','Y','X'}); 
   ds = grpstats(ds,{'S','Y'});
   ds = table(ds.Y,ds.mean_X, 'VariableNames',{'Y','X'}); 
   ds = grpstats(ds,{'Y'});
   cc = corr(ds.mean_X');
   yy = [yy,cc(ix)];
end

BA_mag_Similarity = array2table(yy,'VariableNames',{'INTR','MDDM','CRTX'});

%% Calculate psychometric distance from factor analysis 
load(fws.select('pth',D.Data,'name','factors.mat','output','char'));
psychometricDistance = factor{:,4:end};
simPsychometric = exp(-squareform(pdist(psychometricDistance)).^2);
simDiceMatrix= exp(-squareform(pdist(diceMatrix)).^2);
%% Calculate saliency distance from sal analysis 
load(fws.select('pth',D.Data,'name','cscores.mat','output','char'));

dynamic_saliencyMatrix =  corr(st');
saliencyMatrix =  corr(ss');

ix = tril(true(12),-1);

simDice = simDiceMatrix(ix);
simDynSali = dynamic_saliencyMatrix(ix);
simSali = saliencyMatrix(ix);
simPsyc = simPsychometric(ix);
simMag = BA_mag_Similarity{:,1:3};


%% TOP panel 
%% radviz

letters = arrayfun(@(x) sprintf('%s.',char(x)), (1:6)+96,'un',0);

hf=figure(5);clf;
hf.Position = [50,50,1081,591];% half resolution for display

hf.PaperPositionMode = 'auto';
p = panel(hf);
p.units = 'cm';
p.fontsize=6;
p.pack('v', {0.01 0.49 0.49 0.01})
p.margin = [0.3,0.3,0.5,0.3]; % right bottom left top 
cmap = turbomap(16);
cmap([9,12,14,15],:)=[];
fmap = [28,68,156;81,197,207;227,30,37]./256;

p(2).pack('h', {0.32 0.37 0.03 0.29 0.01});
q = p(2,1).select();
b = q.Position;
axis(q,'off')
ax = axes('Position',[b(1),b(2)-b(4)*0.05,b(3)*0.95,b(4)*0.95]);
plot.radial_scatter(categorical(order,order)',fws.scale(psychometricDistance),{'VS','RE','VR'},fmap,cmap,ax,1,7,0.1)

q = p(2,2).select();

cb = plot.colourHCL(q,psychometricDistance,order,fmap([2,3,1],:),6);

text(cb,2.1,96,'Similar','Rotation',-90,'FontSize',6,'FontWeight','bold','HorizontalAlignment','left')
text(cb,2.1,5,'Dissimilar','Rotation',-90,'FontSize',6,'FontWeight','bold','HorizontalAlignment','right')
q = p(2,4).select();
ax = plot.distance_matrix(q,diceMatrix);
ax.CLim = [0.72,1];

% BOTTOM panel 
p(3).pack('h', {0.02 1/3 1/3 1/3});
p(3).margin = [0.3,.8,.2,0.10]; % right bottom left top 

q = p(3,2).select();

plot.group_scatter_fit(q,simPsyc,simDice,{'Dice'},[0.6,0.1,0.1],...
    [0.3,1 0.6 1 ],'Psychometric Similarity',...
    'Spatial Similarity',[],[0.66,0.66,0.37,0.32],[0.31,0.62 0.5 0.08],'right',2,5);

q = p(3,3).select();

GP = BA_mag_Similarity.Properties.VariableNames;
plot.group_scatter_fit(q,simPsyc,simMag,GP,rmap,[0.3,1 0 1 ],...
    'Psychometric Similarity','Activation Similarity',[],[0.08,0.28,0.37,0.32],[0.31,0.02 0.5 0.32],'right',2,5);

q = p(3,4).select();

plot.group_scatter_fit(q,simPsyc,[simSali,simDynSali],{'Static','Dynamic'},rmap,[ 0.3,1 -0.4 0.4],...
    'Psychometric Similarity','Saliency Similarity',[],[-0.32,-0.24,0.37,0.32],[0.31,-0.38 0.6 0.2],'right',2,5);


b = p.position;
q = axes('Position',b);
axis(q,'off')
text(q,0.02,0.98,letters{1},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.30,0.98,letters{2},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.7,0.98,letters{3},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.02,0.47,letters{4},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.37,0.47,letters{5},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.7,0.47,letters{6},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)

%%
save.pdf(sprintf('%s/Fig_3_new.ai',D.Figures),13,6)

