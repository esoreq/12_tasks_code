function output = wrapSparse3WayModels(id,n,mc,name,data,root)
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
W = {};
df = zeros(1,size(pc,1));
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
for ii=1:mc
rng(seeds(ii));
seed = randi([1e8,1e9],1);
tic
for jj=1:size(pc,1)
ix = c3nl.strDetect(cellstr(Y),[y{pc(jj,1)},'|',y{pc(jj,2)},'|',y{pc(jj,3)}]);
%out = ml.fit.RUSlc(X(ix,:),categorical(cellstr(Y(ix))),S(ix),seed);
lf = 2;
keyboard
out = ml.fit.MCglmnet(X(ix,:),categorical(cellstr(Y(ix))),S(ix),seed,lf);
perf = [perf;[table([ii;ii],[{pc(jj,:)};{pc(jj,:)}],[y(pc(jj,1));y(pc(jj,1))],[y(pc(jj,2));y(pc(jj,2))],[y(pc(jj,3));y(pc(jj,3))],[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','path','C1','C2','C3','Seed','loss'}),out.Performance]];
W{jj} = out.W;
df(jj) = out.df;
if mod(jj,50);fprintf(char(9783));else; fprintf('\n');end
end
toc
output.W{ii} = W;
output.df{ii} = df;
%W(:,ii)= out.W;
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end