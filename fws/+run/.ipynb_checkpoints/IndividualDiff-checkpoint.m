function out = IndividualDiff(subID,data,root,metrics,method)
tic
%% 
% cd '/home/es2814/work/data/12TASKS/'
%  o = run.IndividualDiff(1,'DM_MD','/home/es2814/work/data/12TASKS/','BA/')
% addpath('/rds/general/user/es2814/home/WORK/work/code/c3nl_fusion')
if ~exist('method','var');method='svm';end

fprintf('\nLoading Data\n')
fn = c3nl.select('pth', '/home/es2814/WORK/work/data/12TASKS/ML/Data/','name',[data '.mat']);
fn = fn(c3nl.strDetect(fn,metrics));
load(fn{1});
DataId = ['INDI_' method '_' metrics '_' data];
D=new.folder(DataId,'/home/es2814/WORK/work/data/12TASKS/ML/',{'results'});
rng(22041975);
out = ml.fit.leaveOneOut(X,Y,S,DataId,subID,method);
fprintf('\nSave results\n')
save(sprintf('%s/output_%i.mat',D.results,subID),'out');
end