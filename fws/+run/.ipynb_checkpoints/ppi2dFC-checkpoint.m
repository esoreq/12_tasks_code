function Betas = ppi2dFC(roiSet,modelDir)

[~,roiname] = fileparts(roiSet);
D = new.folder([],[modelDir,'/ML/Data'],{'dFC'});
fn = c3nl.select('pth',[modelDir,'/dFC'],'name',sprintf('*%s*',roiname),'output','char');
L = load.vol(c3nl.select('pth',[modelDir,'/ROI'],'name',sprintf('%s*.nii',roiname),'output','char'));
L  = atlas.reLabel(L);
n = numel(unique(L))-1;
[X,Y,S,dFC]= mine.dFCbetas(fn,n);
save(sprintf('%s/%s.mat',D.dFC,roiname),'X','Y','S','dFC','-v7.3');


end