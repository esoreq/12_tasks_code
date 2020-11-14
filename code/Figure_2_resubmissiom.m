%% figure 2 revisited yet again

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

% %% deal with differences in label order data
order = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};

% Load psychometric distance from factor analysis to define Task order across figures
load(fws.select('pth',D.Data,'name','factors.mat','output','char'));


if ~exist('ROI','var')
    % load parcelation sets & Genrate ROI tables for appendix
    fn = fws.select('pth','./Data/ROIs','name','*.nii');% load ROI's
    fn = flipud(sort(fn));
    mn = fws.select('pth','./Data/Metrics/ROI','name','*.mat');% load ROI activation
    mn = flipud(sort(mn));
    Sets = {'INTR','MDDM','CRTX'};
    ii=1;
    for s=Sets
        [ROI.(s{1}).L,ROI.(s{1}).G] = load.vol(fn{ii});
        ROI.(s{1}).T = fws.label_to_table('label',ROI.(s{1}).L,'grid',ROI.(s{1}).G);
        ROI.(s{1}).T.id_Yeo7(ROI.(s{1}).T.id_Yeo7==0)=8;
        save.table(ROI.(s{1}).T(:,[1:7,10,13,16]),sprintf('%s/ROI_%s.tex',D.Tables,s{1}),'latex','',sprintf('ROI_%s',s{1}));
        save.table(ROI.(s{1}).T(:,[1:7,10,13,16]),sprintf('%s/ROI_%s.csv',D.Tables,s{1}),'csv');
        ii=ii+1;
    end
    % t-test assoication across tasks for each ROI
    ii=1;
    for s=Sets
        tmp = load(mn{ii});
        gp = categories(tmp.Y);
        t1 = table();
        for n=gp'
            ix1 = tmp.Y==n{1};
            [~,p,~,stat] = ttest(tmp.X(ix1,:));
            [pc,hc] = fws.fdr(p,1,0.05);
            t1 = [t1;table({n{1}},hc,p,tmp, stat.tstat.*(stat.tstat>0),stat.tstat.*(stat.tstat<0),stat.tstat,'VariableNames',{'v1','h','p','p_fdr','pt','nt','t'})];
        end
        [h,p,ci,stat]= ttest(t1.t);
        [pc,hc] = fws.fdr(p,1,0.05);
        ROI.(s{1}).roi_t1 = t1;
        if strcmp(s,'INTR')
            tmp = fws.value_to_cmap([0.6,0.6,0.6;0.8667    0.2100    0.0100],[stat.tstat,1.69]);
            ROI.(s{1}).roi_c = tmp(1:end-1,:);
        else
            ix_p = stat.tstat>0;
            ix_n = stat.tstat<0;
            tmp = zeros(numel(ix_p),3);
            tmp1 = fws.value_to_cmap([0.6,0.6,0.6;0.8667    0.2100    0.0100],[stat.tstat(ix_p),1.69]);
            tmp(ix_p,:)= tmp1(1:end-1,:);
            tmp1 = fws.value_to_cmap([0.6,0.6,0.6;0.0100    0.0100    0.5667],[-stat.tstat(ix_n),1.69]);
            tmp(ix_n,:)= tmp1(1:end-1,:);
            ROI.(s{1}).roi_c = tmp;
        end
        ROI.(s{1}).roi_a = fws.scale(1-pc);
        
        ii=ii+1;
    end
    % generate ROI images
    bkg = [0.8,0.8,0.9];
    cmap= [0, 0, 128;170, 255, 195;0, 130, 200;70, 240, 240;60, 180, 75;0, 128, 128;245, 130, 48;128 128 128]./256;
    for  s=Sets
        t = ROI.(s{1}).T;
        for a={'a','rs'}
            ROI.(s{1}).(a{1}) = plot.roi(ROI.(s{1}).L,ROI.(s{1}).G,...
                'plane',a{1},'colour_map',ROI.(s{1}).roi_c,'table',...
                ROI.(s{1}).T,'plot_ids',false,'alpha',0.8);
        end
    end
end


% Grand voxel-wise activation distributions for INTR,MDDM and CRTX
if ~exist('muvar','var')
    fn = fws.select('pth','./Data/Metrics/BA','name','*.mat');
    Sets = {'CRTX','MDDM','INTR'};
    for ii=1:numel(Sets)
        XX.(Sets{ii}) = load(fn{ii});
    end
    
    tmp = XX.INTR;
    Y = categorical(tmp.Y);% all response vectors are the same
    Y = categorical(Y,categories(Y),{'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'});%change names to publication version
    Yo = categorical(Y,order); % force order
    clear Y tmp
    
    data = [];
    muvar = [];
    for s = {'INTR','MDDM','CRTX'}
        XX.(s{1}).Yo  = Yo;
        ds = table(categorical(XX.(s{1}).S),Yo,XX.(s{1}).X, 'VariableNames',{'S','Y','X'});
        ds = grpstats(ds,{'S','Y'});
        ds = table(ds.Y,ds.mean_X, 'VariableNames',{'Y','X'});
        ds = grpstats(ds,{'Y'});
        data.(s{1}) = ds.mean_X;
        muvar = [muvar;table(repmat(s(1),size(ds.mean_X,2),1),[mean(ds.mean_X)]','VariableNames',{'set','BA'})];
    end
end


%% plot multi panel figure

%% define figure structure
hf=figure(1);clf
hf.Position = [200,200,1081,400];% half resolution for display
letters = arrayfun(@(x) sprintf('%s.',char(x)), 97:97+6,'un',0);
p = panel(hf);
p.fontsize=7;
p.pack('v',  {0.3,0.03,0.60 0.07});% the vertical structure of the figure
p.margin = [5,3,3,3];% left, bottom right  top
or = {'a','rs'};
Sets = {'INTR','MDDM','CRTX'};
for ii=1:3
    switch ii
        case 1 % plot ROI volumes
            p(ii).pack('h', {1/3,1/3,1/3,0.01});
            p(ii).margin = [15,3,10,3];
            for jj=1:3
                p(ii,jj).pack('h', {0.5,0.5});
                p(ii,jj).margin = [0,3,0,3];% left, bottom right  top
                for k=1:2
                    q = p(ii,jj,k).select();
                    plot.roi_blend(q,ROI.(Sets{jj}).(or{k}));%roi maps
                end
            end
        case 3
            p(ii).pack('h', {0.01,0.12,0.01,0.26,0.6});
            cmap = flipud([218,126,100;167,30,39;122,33,90]./256);
            for jj=1:5
                switch jj
                    case 2
                        q = p(ii,jj).select();
                        IQR= plot.group_violin(muvar.BA,categorical(muvar.set,Sets),cmap,q,0.3)
                        grid on
                        q.Color = [0.85,0.85,0.85];
                        q.YLabel.String = 'mean BOLD Activation';
                    case 4
                        p(ii,jj).pack('h',{0.3,0.3,0.3});
                        %p(ii,jj).margin = [10,3,10,3];

                        for k=1:3
                            q = p(ii,jj,k).select();
                            xx = data.(Sets{k})';
                            tt = table(repelem(categorical(order'),size(xx,1)),xx(:),'VariableNames',{'T','BA'});
                            plot.group_hist(tt.BA,tt.T,[-2,3],repmat(cmap(k,:),12,1),order,0.01,q,3)
                            title(q,Sets{k})
                            q.Color = [0.85,0.85,0.85];
                            grid(q,'on')
                            q.XLabel.String = '\mu BA';
                            q.FontSize = 6;
                            if k~=1
                                q.YTickLabel='';
                            end
                        end
                    case 5
                        p(ii,jj).pack('h',{1/3,1/3,1/3,0.03});
                        for k=1:3
                            p(ii,jj,k).pack('v',{0.7,0.3});
                            p(ii,jj,k).margin = [10,3,10,3];

                            xx = data.(Sets{k})';
                            cc = corr(xx);
                            [~,~,~,~,explained] = pca(xx');
                            for t=1:2
                                
                                
                                switch t
                                    case 1
                                        p(ii,jj,k,t).pack('h',{1,0.05});
                                        p(ii,jj,k,t).margin = [1,3,1,3];
                                        q = p(ii,jj,k,t,1).select();
                                        imagesc(q , cc);
                                        colormap(q,gray);
                                        
                                        %daspect(q, [1,1,1]);
                                        axis(q ,'off')
                                        q.YDir = 'normal';
                                        q.XDir = 'reverse';
                                        axis(q,'tight')
                                        text(q,6,13, Sets{k},'FontSize',7,...
                                            'VerticalAlignment','bottom','HorizontalAlignment','center','FontWeight','bold');
                                        q = p(ii,jj,k,t,2).select();
                                        plot.color_bar(q,cc(:)," ",gray,5,'h');
                                        q.YAxisLocation = 'right';
                                    case 2
                                        q = p(ii,jj,k,t).select();
                                        b = q.Position;
                                        %ax = axes('Position',[b(1)+b(3)*0.2,b(2),b(3)*0.75,b(4)]);
                                        idx=plot.scree(explained,[],q,cmap(k,:));
                                        grid(q, 'on')
                                        q.Color = [0.85,0.85,0.85];
                                        q.XLabel.String = 'PC'; 
                                        q.YLabel.String = 'Variance';
                                        q.YLabel.Position = [1.05,0.5,1];
                                        q.YLabel.Rotation = -90;
                                end
                            end
                        end
                end
            end
    end
end

%
b = p.position;
q = axes('Position',b);
axis(q,'off')
text(q,0.02,1,letters{1},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.34,1,letters{2},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.67,1,letters{3},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.02,0.67,letters{4},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.20,0.67,letters{5},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.47,0.67,letters{6},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)


%%

save.pdf(sprintf('%s/Fig_2_new.ai',D.Figures),18,7)
       
