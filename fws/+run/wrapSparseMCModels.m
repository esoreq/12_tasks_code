function output = wrapSparseMCModels(id,n,mc,name,data,root,lf)
tic
fprintf('\nLoad Data\n')
load(data);
fprintf('\nPrepare Data\n')
D=new.folder(name,root,{'results'});
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = table();
W = zeros(size(X,2),numel(unique(Y)),mc);
df = zeros(1,mc);
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
if ~exist('lf','var');lf=1;end
for ii=1:mc
rng(seeds(ii));
seed = randi([1e8,1e9],1);
tic
out = ml.fit.MCglmnet(X,Y,S,seed,lf);
perf = [perf;[table([ii;ii],[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','Seed','loss'}),out.Performance]];
W(:,:,ii) = out.W;
df(ii) = out.df;
if mod(ii,50)&ii~=mc;fprintf(char(9783));else; fprintf('\n');end
end
toc
output.W{ii} = W;
output.df{ii} = df;
%W(:,ii)= out.W;
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end