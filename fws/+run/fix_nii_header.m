function fix_nii_header(id,in,out)

D = new.folder([],sprintf('%s/sub-%02d',in,id),{'anat','func'});
fn = c3nl.select('pth',D.func,'name','*.nii.gz');
js = c3nl.select('pth',D.func,'name','*.json');

for ii=1:numel(fn)
    tic
    tmp = fn{ii};
    system(sprintf('gunzip %s',fn{ii}));
    hdr = niftiinfo(tmp(1:end-3));
    V = niftiread(tmp(1:end-3));	 	
    hdr.PixelDimensions(end)=2;
    niftiwrite(V,tmp(1:end-3),'Info',hdr);
    system(sprintf('gzip %s',tmp(1:end-3)));
    toc
end


end
