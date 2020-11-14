function output = DecodingDifferentLabels(id,n,name,data,root)


tic
fprintf('\nLoad Data\n')
load(data);
fprintf('\nPrepare Data\n')
D=new.folder(name,root,{'results'});
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = {};
fprintf('\nModel Data\n')


gp.Psy = ismember(Y,{'Paired' ,'Spatial','ML','SOS' })+ismember(Y,{'Tree' ,'Odd','Rotation','Polygon','Feature' }).*2+ismember(Y,{'Trouble' ,'Grammatical','Digit'}).*3;
gp.Psy = categorical(gp.Psy,1:3,{'WM','Re','VR'});
gp.Resp = ismember(Y,{'Feature' ,'Polygon','Rotation','Trouble','Grammatical','Odd' })+ismember(Y,{'Tree' ,'Paired','SOS'}).*2+ismember(Y,{'Digit' ,'ML','Spatial'}).*3;
gp.Resp = categorical(gp.Resp,1:3,{'FC','SCF','SSeq'});
gp.Domain = ismember(Y,{'Digit' ,'ML','Tree' })+ismember(Y,{'Paired' ,'Odd','Feature','Polygon' }).*2+ismember(Y,{'SOS','Spatial','Rotation'}).*3+ismember(Y,{'Trouble' ,'Grammatical'}).*4;
gp.Domain = categorical(gp.Domain,1:4,{'Digit','Spatial','Object','Verbal'});
gp.Input = ismember(Y,{'SOS' ,'Tree'})+ismember(Y,{'Digit' ,'ML','Spatial','Paired' }).*2+ismember(Y,{'Rotation' ,'Odd','Feature','Polygon','Trouble','Grammatical'}).*3;
gp.Input = categorical(gp.Input,1:3,{'Dyn','Seq','Static'});



seed = randi([1e8,1e9],1);
tic
for f=fieldnames(gp)'
tY = gp.(f{1});
out = ml.fit.eco(X,tY,categorical(S),seed);
perf.(f{1}) = [table({f{1};f{1}},[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','Seed','loss'}),out.Performance];
fprintf(char(9783));
end
toc
fprintf('\nSave results\n')
output.perf = perf;
save(sprintf('%s/output%i.mat',D.results,id),'output');

end