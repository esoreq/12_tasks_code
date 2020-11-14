function results = cleanUpResults(input,del)

if ~exist('del','var');del=0;end
fn = c3nl.select('pth',input,'name','out*.mat');
tic
null = table();
real = table();
F1 = [];
df = [];
W = [];
for ii=1:numel(fn)
    load(fn{ii});
    check = [any(c3nl.strDetect(output.perf.Properties.VariableNames,'C1')),any(c3nl.strDetect(output.perf.Properties.VariableNames,'Negative')),any(c3nl.strDetect(output.perf.Properties.VariableNames,'rsn1')),c3nl.strDetect({input},'DMR'),any(c3nl.strDetect(output.perf.Properties.VariableNames,'classes')),any(c3nl.strDetect(output.perf.Properties.VariableNames,'Model_id')),1];
    switch find(check,1,'first')
    case 1
        tmp = output.perf{:,3:5};
        for ii=1:size(tmp,1);t = join(tmp(ii,:),'_');gp{ii,1}=t{1};end
        ix = c3nl.strDetect(output.perf.Model,'True');
        output.perf.gp = categorical(gp);
        real = [real;unstack(table(output.perf.gp(ix),output.perf.Iter(ix),output.perf.F1(ix,2),'VariableNames',{'gp','mc','F1'}),'F1','gp')];
        null = [null;unstack(table(output.perf.gp(~ix),output.perf.Iter(~ix),output.perf.F1(~ix,2),'VariableNames',{'gp','mc','F1'}),'F1','gp')];
    case 2
        output.perf.gp = categorical(cellstr(categorical(output.perf.Negative).*categorical(output.perf.Positive)));
        ix = c3nl.strDetect(output.perf.Model,'True');
        real = [real;unstack(table(output.perf.gp(ix),output.perf.Iter(ix),output.perf.Acc(ix,2),'VariableNames',{'gp','mc','Acc'}),'Acc','gp')];
        ix = c3nl.strDetect(output.perf.Model,'Null');
        null = [null;unstack(table(output.perf.gp(ix),output.perf.Iter(ix),output.perf.Acc(ix,2),'VariableNames',{'gp','mc','Acc'}),'Acc','gp')];
    case 3
        output.perf.gp = categorical(cellstr(categorical(output.perf.rsn1).*categorical(output.perf.rsn2)));
        ix = c3nl.strDetect(output.perf.Model,'True');
        real = [real;unstack(table(output.perf.Iter(ix),output.perf.gp(ix),output.perf.F1(ix,2),'VariableNames',{'mc','rsn','F1'}),'F1','rsn')];
        null = [null;unstack(table(output.perf.Iter(~ix),output.perf.gp(~ix),output.perf.F1(~ix,2),'VariableNames',{'mc','rsn','F1'}),'F1','rsn')];
    case 4
        ix = c3nl.strDetect(output.perf.Model,'True');
        real = [real;table(output.perf.Iter(ix),output.perf.F1(ix),output.perf.f1r(ix,:),'VariableNames',{'mc','F1','f1r'})];
        null = [null;table(output.perf.Iter(~ix),output.perf.F1(~ix),output.perf.f1r(~ix,:),'VariableNames',{'mc','F1','f1r'})];
    case 5
        class_id = cellfun(@(x) [x{:}],output.perf.classes(1:5:1100,:),'un',0);
        model_id = unique(output.perf.Model_id)';
        gp = categorical(output.perf.Model_id);
        tmp = [];
        for k=model_id
            ix = gp==k{1};
            tmp = [tmp,output.perf.F1(ix,2)];
        end        
        F1 = [F1;tmp];
        %real = [real;[table(repmat(class_id,nnz(gp==k{1})/220,1),'VariableNames',{'class_id'}),array2table(F1,'VariableNames',model_id)]];
        null = [];
    case 6
        model_id = unique(output.perf.Model_id)';
        gp = categorical(output.perf.Model_id);
        tmp = [];
        for k=model_id
            ix = gp==k{1};
            tmp = [tmp,output.perf.F1(ix,2)];
        end        
        F1 = [F1;tmp];
        class_id = '';
        null = [];
    case 7    
        ix = c3nl.strDetect(output.perf.Model,'True');
        real = [real;table(output.perf.Iter(ix),output.perf.F1(ix,2),output.perf.f1r(ix,:),'VariableNames',{'mc','F1','f1r'})];
        ix = c3nl.strDetect(output.perf.Model,'Null');
        null = [null;table(output.perf.Iter(ix),output.perf.F1(ix,2),output.perf.f1r(ix,:),'VariableNames',{'mc','F1','f1r'})];
end
if mod(ii,80);fprintf('.');else;fprintf('\n.');end
end
if isempty(real)
    real = struct('class_id',{class_id},'F1',F1,'model_id',{model_id});
    %[table(repmat(class_id,size(F1,1)/220,1),'VariableNames',{'class_id'}),array2table(F1,'VariableNames',model_id)];
end
results.null = null;
results.real = real;
results.df = df;
results.W = W;

if del
    c3nl.select('pth',input,'name','*.mat','delete',1);
end
save(sprintf('%s/Performance.mat',input),'results','-v7.3');
toc

end