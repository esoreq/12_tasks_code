function output = wrapEcocMCModels(id,n,mc,name,data,root)
tic
fprintf('\nLoad Data\n')
load(data);
fprintf('\nPrepare Data\n')
D=new.folder(name,root,{'results'});
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = table();
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
for ii=1:mc
rng(seeds(ii));
seed = randi([1e8,1e9],1);
tic
out = ml.fit.eco(X,categorical(Y),categorical(S),seed);
perf = [perf;[table([ii;ii],[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','Seed','loss'}),out.Performance]];
if mod(ii,50)&ii~=mc;fprintf(char(9783));else; fprintf('\n');end
end
toc
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
fprintf('\nSave results\n')
output.perf = perf;
save(sprintf('%s/output%i.mat',D.results,id),'output');

end