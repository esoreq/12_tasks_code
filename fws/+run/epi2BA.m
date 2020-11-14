function Betas = epi2BA(roiSet,modelDir)
% takes epi files that corrospond to a univarite spm model and calculates the pairwise roi PPI FSL style 
% example :
% nodesDir = '/group/hampshire_hub/12TASKS/T1';
% modelDir = '/group/hampshire_hub/oldeyal/data/12Tasks/exploratory';
% outDir = '/group/hampshire_hub/12TASKS/Fusion';
% roiSet = '/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ROI/Schaefer100Parcels.nii.gz';


Bepi = c3nl.select('pth',[modelDir,filesep,'POST'],'name','*.nii.gz');
[L,G] = apply.interpolator(roiSet,Bepi{1},'reslice');
[X,Y,S,BA] = mine.Boldbetas(convert.label2Dummy(L),atlas.toTable(L,G),modelDir,0);
D = new.folder([],[modelDir,'/ML/Data'],{'BA'});
[~,roiname] = fileparts(roiSet);
save(sprintf('%s/%s.mat',D.BA,roiname),'X','Y','S','BA','-v7.3');


end