function output = wrapEco3WayModels(id,n,mc,name,data,root)
tic
fprintf('\nLoad Data\n')
load(data);
fprintf('\nPrepare Data\n')
D=new.folder(name,root,{'results'});
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = table();
pc = nchoosek(1:numel(unique(Y)),3);
y = categories(Y);
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
for ii=1:mc
rng(seeds(ii));
seed = randi([1e8,1e9],1);
tic
for jj=1:size(pc,1)
ix = c3nl.strDetect(cellstr(Y),[y{pc(jj,1)},'|',y{pc(jj,2)},'|',y{pc(jj,3)}]);
out = ml.fit.eco(X(ix,:),categorical(cellstr(Y(ix))),S(ix),seed,10,0.2,'onevsone');
perf = [perf;[table([ii;ii],[{pc(jj,:)};{pc(jj,:)}],[y(pc(jj,1));y(pc(jj,1))],[y(pc(jj,2));y(pc(jj,2))],[y(pc(jj,3));y(pc(jj,3))],[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','path','C1','C2','C3','Seed','loss'}),out.Performance]];
if mod(jj,50);fprintf(char(9783));else; fprintf('\n');end
end
toc
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end