function perf = permAsses(id,n,perm,name,data,root,factorID,metric)
tic
fprintf('\nLoad Data\n')
load(data);
fprintf('\nPrepare Data\n')
D=new.folder([name,metric],root,{'results'});
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
tic
gp.Psy = ismember(Y,{'Paired' ,'Spatial','ML','SOS' })+ismember(Y,{'Tree' ,'Odd','Rotation','Polygon','Feature' }).*2+ismember(Y,{'Trouble' ,'Grammatical','Digit'}).*3;
gp.Psy = categorical(gp.Psy,1:3,{'WM','Re','VR'});
gp.Resp = ismember(Y,{'Feature' ,'Polygon','Rotation','Trouble','Grammatical','Odd' })+ismember(Y,{'Tree' ,'Paired','SOS'}).*2+ismember(Y,{'Digit' ,'ML','Spatial'}).*3;
gp.Resp = categorical(gp.Resp,1:3,{'FC','SCF','SSeq'});
gp.Domain = ismember(Y,{'Digit' ,'ML','Tree' })+ismember(Y,{'Paired' ,'Odd','Feature','Polygon' }).*2+ismember(Y,{'SOS','Spatial','Rotation'}).*3+ismember(Y,{'Trouble' ,'Grammatical'}).*4;
gp.Domain = categorical(gp.Domain,1:4,{'Digit','Spatial','Object','Verbal'});
gp.Input = ismember(Y,{'SOS' ,'Tree'})+ismember(Y,{'Digit' ,'ML','Spatial','Paired' }).*2+ismember(Y,{'Rotation' ,'Odd','Feature','Polygon','Trouble','Grammatical'}).*3;
gp.Input = categorical(gp.Input,1:3,{'Dyn','Seq','Static'});


factors =  fieldnames(gp);
fprintf('\nModel Data\n')
Yf =  gp.(factors{factorID});
seed = randi([1e8,1e9],1);
if iscell(S);S = categorical(S);end
if iscell(Y);Y = categorical(Y);end

[box,oob] = get.partition(S,'groupSample',0.25,seed,double(S));
XR = X(oob,:);Xt = X(box,:);
tic
L = templateSVM('Standardize',1);
mdl = fitcecoc(Xt,Yf(box),'Learners',L,'coding','onevsall'); % learn
[F1,f1] = ml.score.F1(Yf(oob),predict(mdl,XR));
toc
[~,ix]= unique(Y);
nc = sum(dummyvar(Yf(ix)));
prop = [];
for ii=1:numel(nc)
   prop= [prop,ii*(1:nc(ii)).^0]; 
end
C = unique(arrayfun(@(x) sprintf('C%i',x),prop,'un',0));
YD = dummyvar(Y);
perf=[];
perf =[perf; table({factors{factorID}},seed,1:12,nc./numel(unique(Y)),F1,f1,'VariableNames',{'name','seed','perm','prop','F1','f1'})];
tic
for ii=1:perm
    Perms = randperm(12,12);
    Ys = categorical(sum(YD(:,Perms).*prop,2),1:numel(nc),C);
    mdl = fitcecoc(Xt,Ys(box),'Learners',L,'coding','onevsall'); % learn
    [F1,f1] = ml.score.F1(Ys(oob),predict(mdl,XR));
    perf =[perf; table({'perm'},seed,Perms,nc,F1,f1,'VariableNames',{'name','seed','perm','prop','F1','f1'})];
end
toc
Yt = Ys(box);
mdl = fitcecoc(Xt,Yt(randperm(size(Yt,1))),'Learners',L,'coding','onevsall'); % learn
[F1,f1] = ml.score.F1(Ys(oob),predict(mdl,XR));
perf =[perf; table({'null'},seed,Perms,nc,F1,f1,'VariableNames',{'name','seed','perm','prop','F1','f1'})];

toc
fprintf('\nSave results\n')

save(sprintf('%s/%s_%i_output%i.mat',D.results,metric,factorID,id),'perf');