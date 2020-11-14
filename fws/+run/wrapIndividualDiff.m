function out = wrapIndividualDiff(subID,data,root,metrics)
tic
%% 
% cd '/home/es2814/work/data/12TASKS/'
%  o = run.wrapIndividualDiff(1,'DM_MD','/home/es2814/work/data/12TASKS/',{'BA/','dFC/'})

fprintf('\nLoading Data\n')
fn = c3nl.select('pth', '/home/es2814/work/data/12TASKS/ML/Data/','name',[data '.mat']);
fn = fn(c3nl.strDetect(fn,strjoin(metrics,'|')));
XX = {};
DataId = cell(1,numel(fn));
D=new.folder(data,'/home/es2814/work/data/12TASKS/ML/',{'results'});
for jj=1:numel(fn)
    load(fn{jj});
    name = strsplit(  fileparts(fn{jj}),'/');
    DataId{jj} = name{end};
    XX(jj) = {X};
    fprintf('\nPrepare %s Data\n',name{end});
end
rng(22041975);
out = ml.fit.stackedLeaveOneOut(XX,Y,S,DataId,subID);
fprintf('\nSave results\n')
save(sprintf('%s/output_%i.mat',D.results,subID),'out');
end