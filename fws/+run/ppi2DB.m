function Betas = ppi2DB(roiSet,modelDir)

[~,roiname] = fileparts(roiSet);
D = new.folder([],[modelDir,'/ML/Data'],{'PPI'});
fn = c3nl.select('pth',[modelDir,'/PPI'],'name',sprintf('*%s*',roiname),'output','char');
L = load.vol(c3nl.select('pth',[modelDir,'/ROI'],'name',sprintf('%s*.nii',roiname),'output','char'));
L  = atlas.reLabel(L);
n = numel(unique(L))-1;
[X,Xz,Y,S,PPI]= mine.PPIbetas(fn,n);
save(sprintf('%s/%s.mat',D.PPI,roiname),'X','Y','S','PPI','-v7.3');


end