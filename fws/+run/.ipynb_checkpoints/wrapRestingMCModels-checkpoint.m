function output = wrapRestingMCModels(id,n,mc,name,data,root)
tic
fprintf('\nLoad Data\n')
load(data);
roiname = strsplit(name,'_');

[L,G] = load.vol(c3nl.select('pth','/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ROI/','name',[roiname{1},'*'],'output','char')); % load ROI set volume 
TT = atlas.toTable(L,G); % map integers to resting state networks 
[AB,ix,pairs] = get.connIdx(height(TT),double(categorical(TT.name_Yeo7))); % get inter and intra mappings 
rsnl = matlab.lang.makeValidName(unique(TT.name_Yeo7)); % resting state network labels 
ix1 = find(triu(true(height(TT)),1));

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

for jj=1:size(pairs,1)
    fs  = ismember(AB(ix1),pairs(jj,3));
    out = ml.fit.eco(X(:,fs),Y,S,seed,10,0.3,'onevsall');
    perf = [perf;[table([ii;ii],[rsnl(pairs(jj,1));rsnl(pairs(jj,1))],[rsnl(pairs(jj,2));rsnl(pairs(jj,2))],[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','rsn1','rsn2','Seed','loss'}),out.Performance]];
fprintf(char(9783));
end
for jj=1:7
    ix = sum(ismember(pairs(:,1:2),jj),2)-1==0;
    fs  = ismember(AB(ix1),pairs(ix,3));
    out = ml.fit.eco(X(:,fs),Y,S,seed,10,0.3,'onevsall');
    perf = [perf;[table([ii;ii],[rsnl(jj);rsnl(jj)],{'rest';'rest'},[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','rsn1','rsn2','Seed','loss'}),out.Performance]];
    fprintf(char(9783));
end
out = ml.fit.eco(X,Y,S,seed,10,0.3,'onevsall');
perf = [perf;[table([ii;ii],{'full';'full'},{'full';'full'},[seed;seed],[out.loss;out.loss],'VariableNames',{'Iter','rsn1','rsn2','Seed','loss'}),out.Performance]];
fprintf('\n');
end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end