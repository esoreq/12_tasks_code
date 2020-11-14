function output = wrapEcoBinModels(id,n,mc,name,data,root)

% output = wrapEcoBinModels(1,1,1,'test','/home/es2814/work/data/12TASKS/ML/Data/BA/L2_200_Diff.mat','/home/es2814/work/data/12TASKS')
tic
fprintf('\nLoad Data\n')
load(data);
fprintf('\nPrepare Data\n')
D=new.folder(name,root,{'results'});
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = table();
pc = nchoosek(1:numel(unique(Y)),2);
y = categories(Y);
W = zeros(size(X,2),size(pc,1));
df = zeros(1,size(pc,1));
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
for ii=1:mc
rng(seeds(ii));
seed = randi([1e8,1e9],1);
tic
for jj=1:size(pc,1)
ix = c3nl.strDetect(cellstr(Y),[y{pc(jj,1)},'|',y{pc(jj,2)}]);
%out = ml.fit.RUSlc(X(ix,:),categorical(cellstr(Y(ix))),S(ix),seed);
out = ml.fit.eco(X(ix,:),categorical(cellstr(Y(ix))),S(ix),seed);
perf = [perf;[table([ii;ii],[y(pc(jj,1));y(pc(jj,1))],[y(pc(jj,2));y(pc(jj,2))],[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','Negative','Positive','Seed','loss'}),out.Performance]];

if mod(jj,50);fprintf(char(9783));else; fprintf('\n');end
end
toc
%W(:,ii)= out.W;
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end