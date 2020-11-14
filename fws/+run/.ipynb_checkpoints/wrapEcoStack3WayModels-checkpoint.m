function output = wrapEcoStack3WayModels(id,n,mc,name,data,root,dataID)
tic
r=0;
X = {};
for ii=1:numel(data)
Data.(['I',num2str(ii)]) = load(data{ii});
X{ii} = Data.(['I',num2str(ii)]).X;
end
fprintf('\nPrepareing Data\n')
D=new.folder(name,root,{'results'});
if ~exist(sprintf('%s/output%i.mat',D.results,id),'file')|r
Y = Data.I1.Y;
S = Data.I1.Y;
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
xx = {};
for ii=1:numel(X)
    xx{ii} =  X{ii}(ix,:);
end
out = ml.fit.stacked_eco(xx,categorical(cellstr(Y(ix))),S(ix),seed,dataID);
perf = [perf;[table(repmat(jj,height(out.Performance),1),repmat({pc(jj,:)},height(out.Performance),1),repmat({y(pc(jj,1)),y(pc(jj,2)),y(pc(jj,3))},height(out.Performance),1),'VariableNames',{'Iter','path','classes'}),out.Performance]];
if mod(jj,50);fprintf(char(9783));else; fprintf('\n');end
end
toc
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end