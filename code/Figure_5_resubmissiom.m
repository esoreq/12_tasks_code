%% figure 5 revisited 

% 1st row
% scatter plots of classification perfomance
% 2st row
% radar plots of f1-micro performance
% 3st row
% one-vs-one F1 classification perfomance vs psychometric distnace



clear;clc;close all
path = fileparts(matlab.desktop.editor.getActiveFilename);
cd (path)
addpath ../fws
cd ..
D = new.folder([],pwd,{'Data','Figures','Tables'});
%% Load data
pref_permutation = load(fws.select('name','DS_permutation.mat','output','char'));
pref_response = load(fws.select('name','DS_response.mat','output','char'));



load(fws.select('pth','./Data/Metrics/BA','name','intersectionROI.mat','output','char'));
Y = categorical(Y);% all response vectors are the same
order = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};
y = categories(Y);
Y = categorical(Y,y,{'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'});%change names to publication version
Yo = categorical(Y,order); % force order 
clear Y X S

%% manually assign labels
% Visual domain
%Domain = ismember(Y,{'Digit' ,'ML','Tree' })+ismember(Y,{'Paired' ,'Odd','Feature','Polygon' }).*2+ismember(Y,{'SOS','Spatial','Rotation'}).*3+ismember(Y,{'Trouble' ,'Grammatical'}).*4;
Domain = ismember(Yo,{'DS' ,'ML','TT' })+ismember(Yo,{'PA' ,'OO','FM','IP' }).*2+ismember(Yo,{'SO','SS','RO'}).*3+ismember(Yo,{'CW' ,'GR'}).*4;
YY.Domain = categorical(Domain,1:4,{'Digit','Spatial','Object','Verbal'});

% Temporal load
%Input = ismember(Y,{'SOS' ,'Tree'})+ismember(Y,{'Digit' ,'ML','Spatial','Paired' }).*2+ismember(Y,{'Rotation' ,'Odd','Feature','Polygon','Trouble','Grammatical'}).*3;
Input = ismember(Yo,{'SO' ,'TT'})+ismember(Yo,{'DS' ,'ML','SS','PA' }).*2+ismember(Yo,{'RO' ,'OO','FM','IP','CW','GR'}).*3;
YY.Input = categorical(Input,1:3,{'Dyn','Seq','Sta'});

% Psycometric factor
%Psy = ismember(Y,{'Paired' ,'Spatial','ML','SOS' })+ismember(Y,{'Tree' ,'Odd','Rotation','Polygon','Feature' }).*2+ismember(Y,{'Trouble' ,'Grammatical','Digit'}).*3;
Psy = ismember(Yo,{'PA' ,'SS','ML','SO' })+ismember(Yo,{'TT' ,'OO','RO','IP','FM' }).*2+ismember(Yo,{'CW' ,'GR','DS'}).*3;
YY.Psy = categorical(Psy,1:3,{'WM','Re','VR'});

% Response type % removed for simplicity sake
%Resp = ismember(Y,{'Feature' ,'Polygon','Rotation','Trouble','Grammatical','Odd' })+ismember(Y,{'Tree' ,'Paired','SOS'}).*2+ismember(Y,{'Digit' ,'ML','Spatial'}).*3;
%Resp = ismember(Yo,{'FM' ,'IP','RO','CW','GR','OO' })+ismember(Yo,{'TT' ,'PA','SO'}).*2+ismember(Yo,{'DS' ,'ML','SS'}).*3;
%YY.Resp = categorical(Resp,1:3,{'FC','IN','SC'});



labels.Psy = categorical({'VS','RE','VR'});
%labels.Resp = categorical({'FC','SCF','SSeq'});
labels.Domain = categorical({'Digit','Spatial','Object','Verbal'});
labels.Input = categorical({'Dyn','Seq','2FC'});

%%

hf=figure(5);
clf
% create colour palletes for each factor 
HSV = min(max(hsv(360)-0.01,0.01),0.95);

hf.Position = [50,50,1081,500];% half resolution for display
p = panel(hf);
% Define rows proportion
p.pack('v',{0.33,0.33,0.33 0.01});
p.units = 'cm';
p.fontsize=6;
p.margin = [.6,.4,.6,.4];
set = reshape(97:108,3,[])';
letters = arrayfun(@(x) sprintf('%s.',char(x)), set(:),'un',0);
%cmap{3} = [151,176,219;137,125,186;53,90,169]./256;
cmap{3} = [60,164,181;158,207,126;65,153,69;20,73,35]./256;
cmap{2} = [251,174,35;244,136,35;153,92,40]./256;
cmap{1} = [126,29,90;212,32,39;226,127,101]./256;
DS = pref_permutation.DS;
DSf = pref_response.DS;
[v,ix1] = unique(Yo);
metrics = {'BA' 'dFC'};

Fac = {'Psy','Input','Domain'};
k = 1;
for ii = 1:numel(Fac)
    p(ii).pack('h',{0.22,0.26,0.28,0.24})
    
    for jj=1:4
        if jj==4
             p(ii,jj).margin  = [.6,.4,.4,.4];
        end
        q = p(ii,jj).select();
        switch jj
            case 1
                text(q,-0.05,1,letters{k},'HorizontalAlignment','left','FontWeight','bold','FontSize',9)
                axis(q,'off')
                
            case 2
                b =q.Position;
                text(q,-0.05,1,letters{k},'HorizontalAlignment','left','FontWeight','bold','FontSize',9);
                axis(q,'off');
                ax = axes('Position',[b(1)+b(3)*0.15,b(2)+b(4)*0.2,b(3)*0.85,b(4)*0.55]);
                nl = numel(labels.(Fac{ii}));
                M = (dummyvar(YY.(Fac{ii})(ix1)).*(1:nl))';
                tmap = cmap{ii};
                for r=1:12
                    [I,~] = find(M(:,r));
                    text(ax,r,I,char(9679),'color',tmap(I,:),'FontSize',10,'HorizontalAlignment','center');
                    text(ax,r,I-0.5,order{r},'color','k','Rotation',-45,'FontSize',6,'HorizontalAlignment','center');
                end
                ax.XTick = [];
                ax.YTick = 1:nl;
                ax.YTickLabel = labels.(Fac{ii});
                ax.Color = 'none';
                axis(ax,[0,13,0.5,nl+.5]);
                ax.YDir = 'reverse';
                ax.FontSize = 6;
                %daspect(q,[16,12,1]);
                
            case 3

                b =q.Position;
                text(q,-0.05,1,letters{k},'HorizontalAlignment','left','FontWeight','bold','FontSize',9)
                axis(q,'off');
                tmp = DS.(Fac{ii});
                tmp.name = categorical(tmp.name);
                for m = 1:numel(metrics) 
                    ix = fws.strDetect(tmp.metric,metrics{m});
                    xx = tmp(ix,:);
                    ax = axes('Position',[b(1)+b(3)*0.1,b(2)+b(4)*(0.1+(m-1)*0.425),b(3)*0.65,b(4)*0.35]);
                    ax.FontSize = 6;
                    tmap= [cmap{ii}(1,:).^4;.6,.6,.6;cmap{ii}(1,:).^0.5];
                    plot.group_hor_hist(xx.F1,xx.name,tmap,ax,0.9)
                    axis(ax,[0,100,0,max(ax.YLim)]);
                    ax.Color = [0.85,0.85,0.85];
                    P = fws.empiricalP(xx.F1(xx.name=='perm'),xx.F1(xx.name==Fac{ii}),nnz(xx.name=='perm'));
                    yy = max(ax.YLim)*0.95;
                    Xx = mean(xx.F1(xx.name==Fac{ii}));
                    line(ax,[Xx,Xx],[yy,min(ax.YLim)],'color',tmap(end,:),'LineWidth',1.5);
                    plot(ax,Xx,yy,'Marker','.','MarkerSize',10,'MarkerEdgeColor',tmap(end,:).^0.5);
                    text(ax,Xx,yy*1.1,sprintf("$p= %0.3f$",P),'Interpreter','latex','HorizontalAlignment','center','FontSize',6);
                    grid on
                    ax.YTickLabel ='';
                    ax.YLabel.String = metrics{m};
                    if m>1;ax.XTickLabel ='';
                    else
                        yy = fliplr(quantile(ax.YLim,[0.35,0.5,0.65]));
                        cat = categories(xx.name);
                        for r=1:numel(yy)
                            text(110*yy(r).^0,yy(r),cat{r},'FontSize',6);
                            text(102*yy(r).^0,yy(r),char(9679),'color',tmap(r,:),'FontSize',8);
                        end
                        ax.XLabel.String = 'F1';
                    end
                end        
                                
            case 4
                tmp = DS.(Fac{ii});
                tmp = tmp(fws.strDetect(tmp.name,Fac{ii}),:);
                text(q,-0.075,1,letters{k},'HorizontalAlignment','left','FontWeight','bold','FontSize',9)
                x = tmp.f1(fws.strDetect(tmp.metric,'dFC'),:);
                y = tmp.f1(fws.strDetect(tmp.metric,'BAvx'),:);
                y = y(1:100,:);
                gp_f1 = repelem(labels.(Fac{ii}),size(x,1));
                %[ylim_bottom,ylim_top,x_text,x_marker]
                b =q.Position;
                axis(q,'off');
                q.FontSize = 6;
                if strcmp(Fac{ii},'Domain');lg = [0.07,0.5,11,1];else;lg = [0.09,0.37,11,1];end
                plot.scatter_histogram(q,x(:),y(:),gp_f1(:),cmap{ii},[0,100],{'dFC','BA'},lg,[],6);
                
                
        end
        k=k+1;
    end
end
%
for ii = 1:numel(Fac)
    tmp = DS.(Fac{ii});
    ds = grpstats(tmp,{'metric','name'},'mean','DataVars',{'F1','f1'});
end

%%
save.pdf(sprintf('%s/Fig_5_new.ai',D.Figures),18,9)

%close all


%% 
for ii=1:3
    tmp = DS.(Fac{ii});
    tmp = tmp(~fws.strDetect(tmp.name,'perm'),:);
    tmp.iteridx = cell2mat(cellfun(@(x) str2double(x),    cellfun(@(x) erase(x,'output'), tmp.iter,'un',0),'un',0));  
    tmp = sortrows(tmp,'iteridx');
    tmp(find(fws.strDetect(tmp.iter,'output101'),1,'first'):end,:)=[];
    tmp(fws.strDetect(tmp.name,'null'),:)=[];
    mdl = fitlme(tmp,'F1 ~ 1+metric+(1|seed)');
   mdl
end


