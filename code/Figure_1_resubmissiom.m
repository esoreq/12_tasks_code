%% figure 1 revisited yet again 

% top panel is the mip of all tasks 1/3
% Bottom panel is has three parts 
% part 1 intersection vs union
% part 2 tree map showing the overlap
% part 3 the t-statistics map and the overlap map

clear;clc;close all
path = fileparts(matlab.desktop.editor.getActiveFilename);
cd (path)
addpath ../fws
cd ..
D = new.folder([],pwd,{'Data','Figures','Tables'});

% %% deal with differences in label order data
% hfs = categorical({'DS','FM','GR','ML','OO','PA','IP','RO','SO','SS','TT','CW'});
order = {'PA','SS','ML','SO','TT','OO','RO','FM','IP','CW','GR','DS'};

% Load psychometric distance from factor analysis to define Task order across figures
load(fws.select('pth',D.Data,'name','factors.mat','output','char'));



% Generate maximum intenstiy projection in axial view
if ~exist('im','var')
    fn = sort(fws.select('pth','./Data','name','spm*'));
    [~,ix] = ismember(order,factor.ShortID);
    im = [];
    cmap = turbomap(16);
    cmap([9,12,14,15],:)=[];
    for ii=1:numel(fn)
        [Y,G] = load.vol(fn{fws.strDetect(fn,factor.TaskId{ii})});
        n=order{ii};
        if ~isfield(im,n)
            tmap=fws.cmap2tone(cmap(ii,:),[0.1,0.5,0.8,1],100,2);
            im.(n) = plot.mip(Y,G,'plane','a','color',tmap);
        end
    end
end


% generate union, intersection and load z-test volume
if ~exist('Z','var')
    [Z,zg] = load.vol(fws.select('pth','./Data','name','all_001v_unc_05c_FWE_u*','output','char'));
    [Y,G] = load.vol(fn{1});
    Z = fws.interpolator('source_volume',Z,'source_grid',zg,...
                         'target_volume',Y,'target_grid',G   );
    Y={};
    for ii=1:numel(fn)
        Y{ii} = load.vol(fn{fws.strDetect(fn,factor.TaskId{ii})});
    end    
    U = nanmean(cat(4,Y{1:12}),4);
    Im = all(~isnan(cat(4,Y{1:12})),4);
    I = cellfun(@(x) x.*Im,Y,'un',0);
    I = cat(4,I{1:12});
    I = nanmin(I,[],4);
end

% Generate percentage of overlap volume
if ~exist('p_labels','var')
    O = sum(~isnan(cat(4,Y{1:12})),4);
    perOverlap = cell2mat(arrayfun(@(x) nnz(O==x)/nnz(O),1:12,'un',0));
    p_labels = arrayfun(@(a,x) sprintf('%i \n %.1f%%',a,x),1:12,perOverlap*100,'un',0);
end
cmap = {[240,76,0],[],[191,30,5],[0,130,240]};
if ~exist('im1','var')
    tmp = {I,Z,U,O};
    labels = {'Intersection','Zstat','Union','Overlap'};
    for ii=1:4
        if ii~=4
            tmap=hot;
        else 
            tmap=flipud(fws.cmap2tone([0,130,240]./256,[0.4,1],12,1.5));

        end
        for or = {'a','rs'}
            im1.(labels{ii}).(or{1}) = plot.mip(tmp{ii},G,'plane',or{1},'color',tmap);
        end
    end
end

%% plot multi panel figure

%% define figure structure
hf=figure(1);clf
hf.Position = [200,200,1000,500];% half resolution for display

letters = arrayfun(@(x) sprintf('%s.',char(x)), 97:97+6,'un',0);
p = panel(hf);
p.pack('v', {0.25 0.02 0.73})% the vertical structure of the figure
p.margin = [10,10,5,5];% left, bottom right  top
tic
% top panel all brain mips in jet colour
p(1).pack('h', repmat({1/12},1,12));
p(1).margin = [1,0,0,1];

for ii=1:12
    n=order{ii};
    q = p(1,ii).select();
    axis(q,'off');
    ax = axes('Position',q.Position);
    plot.mip_blend(ax,im.(n));
    text(ax,0.5,-0.2,[factor.TaskId(ii);n],'HorizontalAlignment','center','FontUnits','points','FontSize',7)
end
% bottom panel logical brain mips and tree map 
p(3).pack('h', {0.6 0.4});
%p(2).margin = [10,10,5,15];% left, bottom right  top
%
or = {'a','rs'};
c = 1;
for ii=1:2
    switch ii
        case 1
            p(3,ii).pack('h', repmat({1/4},1,4));
            p(3,ii).margin = [1,0,0,1];
            for jj=1:4
                p(3,ii,jj).margin = [2,2,2,2];
                p(3,ii,jj).pack('v', {0.6,0.4});
                for k=1:2
                    q = p(3,ii,jj,k).select();
                    b = q.Position;axis(q,'off')
                    q = axes('Position',[b(1),b(2)+b(4)*0.1,b(3)*0.9,b(4)*0.8]);
                    plot.mip_blend(q,im1.(labels{c}).(or{k}))
                end
                text(q,0.5,-0.1,labels{c},'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','points','FontSize',8)
                c = c+1;
            end
        case 2
            q = p(3,2).select();
            axis(q,'off');
            b = q.Position;
            ax = axes('Position',[b(1),b(2),b(3),b(4)*0.9]);
            cmap=fws.cmap2tone([0,130,240]./256,[0.4,1],12,1.5);
            plot.tree_map(ax,perOverlap,p_labels,flipud(cmap),0.055,1.75);
    end 
end
tmp = {I,Z,U,O};

for jj=1:4
    b = p(3,1,jj).position;
    b(1) = b(1) + b(3)*0.1;
    b(3) = b(3) * 0.7;
    b(2) = b(2) + b(4)*0.415;
    b(4) = b(4) * 0.03;
    ax = axes('Position',b);
    if jj<4
        plot.color_bar(ax,tmp{jj},'',hot,3,'v')
    else 
        tmap=flipud(fws.cmap2tone([0,130,240]./256,[0.4,1],12,1.5));
        plot.color_bar(ax,tmp{jj},'',tmap,3,'v')
        ax.XTickLabel = {'1','6','12'};
    end
    ax.FontSize = 7;
    
end

%{


%}

%
b = p.position;
q = axes('Position',b);
axis(q,'off')
text(q,0,1,letters{1},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0,0.63,letters{2},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9);
text(q,0.17,0.63,letters{3},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.315,0.63,letters{4},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.46,0.63,letters{5},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
text(q,0.6,0.63,letters{6},'HorizontalAlignment','right','FontWeight','bold','FontUnits','points','FontSize',9)
%

save.pdf(sprintf('%s/Fig_1_new.ai',D.Figures),18,10)
