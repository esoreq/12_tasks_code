function Betas = epi2BAvx(roiSet,modelDir)
% takes epi files that corrospond to a univarite spm model and calculates the pairwise roi PPI FSL style 
% example :
% nodesDir = '/group/hampshire_hub/12TASKS/T1';
% modelDir = '/group/hampshire_hub/oldeyal/data/12Tasks/exploratory';
% outDir = '/group/hampshire_hub/12TASKS/Fusion';
% roiSet = '/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ROI/Schaefer100Parcels.nii.gz';


Bepi = c3nl.select('pth',[modelDir,filesep,'POST'],'name','*.nii.gz');
[L,G] = apply.interpolator(roiSet,Bepi{1});
[X,Y,S] = mine.Boldbetas(L>0,[],modelDir,0);
D = new.folder([],[modelDir,'/ML/Data'],{'BAvx'});
[~,roiname] = fileparts(roiSet);
save(sprintf('%s/%s.mat',D.BAvx,roiname),'X','Y','S','-v7.3');


end