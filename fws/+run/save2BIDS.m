function save2BIDS(id,in,out)
%{
id = 1
in  = '/rdsgpfs/general/user/es2814/home/WORK/work/data/12TASKS'
out = '/rdsgpfs/general/user/es2814/home/WORK/work/data/12TASKS/BIDS'



%}




if ~isempty(id)

  % (1) for each subject construct folder hierarchy i.e. sub-<num>/ {anat,func})
  
  D = new.folder([],sprintf('%s/sub-%02d',out,id),{'anat','func'});
  
  % (2) convert id to subject name
  
  d = new.folder([],in,{'PRE','LOG'});
  fn = c3nl.select('pth',d.LOG,'type','d','maxdepth',1,'mindepth',1);
  subj =strsplit(fn{id},'/');subj=subj{end};
  d = new.folder(subj,in,{'PRE','LOG'});
  % (3) copy anatomy gunzip it and rename it to the BIDS format  
  anat = c3nl.select('pth',d.PRE,'name','s1*.nii');
  if isempty(anat)
      anat = c3nl.select('pth',d.PRE,'name','s*.nii');
  end      
  if ~exist(sprintf('%s/sub-%02d_T1w.nii.gz',D.anat,id),'file')	
  copyfile(anat{1},sprintf('%s/sub-%02d_T1w.nii',D.anat,id));
  
  % (4) anonymize it using spm_deface 
  addpath '/rds/general/user/es2814/home/WORK/work/code/c3nl_fusion/3rdParty/spm12';
  anno = spm_deface(struct('images',{sprintf('%s/sub-%02d_T1w.nii',D.anat,id)}));
  
  % (5) gzip anonymized data to new file  
  
  system(sprintf('gzip -c %s > %s/sub-%02d_T1w.nii.gz',anno{1},D.anat,id));
  
  % (6) delete nifti files in folder 
  
  system(sprintf('rm -rf %s/*.nii',D.anat));
  
  % (7) construct json hdr file for anatomy 
  
  log = c3nl.select('pth',d.LOG,'name','*.mat');
  load(log{c3nl.strDetect(log,subj)});
  hdr = Data.MPRAGE.MPRAGE.fullhdr;
  anat_json = struct('Manufacturer',hdr.Manufacturer,...
                     'ManufacturersModelName',' ',...
                     'MagneticFieldStrength',hdr.MagneticFieldStrength,...
                     'DeviceSerialNumber',hdr.DeviceSerialNumber,...
                     'StationName',hdr.StationName,...
                     'SoftwareVersions',hdr.SoftwareVersion,...
                     'HardcopyDeviceSoftwareVersion','',...
                     'ReceiveCoilName',' ',...
                     'ReceiveCoilActiveElements',' ',...
                     'GradientSetType',' ',...
                     'MatrixCoilMode',' ',...
                     'CoilCombinationMethod',' ',...
                     'PulseSequenceType',hdr.ProtocolName,...
                     'ScanningSequence',hdr.ScanningSequence,...
                     'SequenceVariant',hdr.SequenceVariant,...
                     'ScanOptions',hdr.ScanOptions,...
                     'SequenceName',hdr.SequenceName,...
                     'PulseSequenceDetails',' ',...
                     'NonlinearGradientCorrection',' ',...
                     'NumberShots',' ',...
                     'ParallelReductionFactorInPlane',' ',...
                     'ParallelAcquisitionTechnique',' ',...
                     'PartialFourier',' ',...
                     'PartialFourierDirection',' ',...
                     'WaterFatShift',' ',...
                     'EchoTrainLength',hdr.EchoTrainLength,...
                     'EchoTime',hdr.EchoTime./1000,...
                     'InversionTime',hdr.InversionTime./1000,...
                     'SliceEncodingDirection',' ',...
                     'DwellTime',' ',...
                     'FlipAngle',hdr.FlipAngle,...
                     'MultibandAccelerationFactor',' ',...
                     'AnatomicalLandmarkCoordinates',' ',...
                     'InstitutionAddress',hdr.InstitutionAddress,...
                     'InstitutionalDepartmentName',' ',... %hdr.InstitutionalDepartmentName,...
                     'ContrastBolusIngredient',' ',...
                     'InstitutionName',hdr.InstitutionName);
  
  % (8) save anatomy hdr in JSON format             
  
  anat_json_str = jsonencode(anat_json);
  fid = fopen(sprintf('%s/sub-%02d_T1w.json',D.anat,id), 'w');
  if fid == -1, error('Cannot create JSON file'); end
  fwrite(fid, anat_json_str, 'char');
  fclose(fid);
else 
  log = c3nl.select('pth',d.LOG,'name','*.mat');
  load(log{c3nl.strDetect(log,subj)});
  end
                   
  % (9) copy epi files and rename them 
  
  fn = c3nl.select('pth',d.PRE,'name','f4D*');
  fn = fn(c3nl.strDetect(fn,sprintf('EPI&%s',subj)));
  
for dn = Data.fileMapping.PREFolder'
    dn = dn{1};
    ix = c3nl.strDetect(fn,sprintf('%s/',dn));
    if ~isempty(ix)
        disp(Data.fileMapping.taskName{ix});
        output = sprintf('%s/sub-%02d_task-%s_run-01_bold.nii',D.func,id,Data.fileMapping.taskName{ix});
	if ~exist([output,'.gz'],'file')
        	copyfile(fn{ix},output); 
        	fprintf('*')
        	gzip(output);
	end	
    else 
        disp('PROBLEM WITH %s' ,dn);
    end
end

system(sprintf('rm -rf %s/*.nii',D.func));

     
  % (10) construct epi hdr files 
for r = Data.fileMapping.PREFolder'
      ix = c3nl.strDetect(fn,sprintf('%s/',r{1}));
      hdr = Data.EPI.(r{1}).header;
      nVx = hdr.Private_0051_100b;
      nVx = str2double(nVx(1:(strfind(nVx, '*')-1)));
      BW = hdr.Private_0019_1028; 
      bold_json = struct('TaskName',Data.fileMapping.taskName{ix},...
      'RepetitionTime',hdr.RepetitionTime/1000,...
      'Manufacturer', hdr.Manufacturer,...
      'ManufacturerModelName', hdr.ManufacturerModelName,...
      'MagneticFieldStrength', hdr.MagneticFieldStrength,...
      'DeviceSerialNumber', hdr.DeviceSerialNumber,...
      'SoftwareVersions',hdr.SoftwareVersion,...
      'ReceiveCoilName', ' ',...
      'GradientSetType', ' ',...
      'MRTransmitCoilSequence', ' ',...
      'MatrixCoilMode', ' ',...
      'CoilCombinationMethod', ' ',...
      'PulseSequenceType', ' ',...
      'PulseSequenceDetails', ' ',...
      'NumberShots', ' ',...
      'ParallelReductionFactorInPlane', ' ',...
      'ParallelAcquisitionTechnique', ' ',...
      'PartialFourier', ' ',...
      'PartialFourierDirection', ' ',...
      'EffectiveEchoSpacing', 1/(BW*nVx),... %Effective Echo Spacing (s) = 1/(BandwidthPerPixelPhaseEncode * MatrixSizePhase)
      'TotalReadoutTime', (nVx-1)/(BW*nVx),... %TotalReadoutTime = EffectiveEchoSpacing * (ReconMatrixPE - 1)
      'EchoTime', hdr.EchoTime/1000,...
      'InversionTime', ' ',...
      'SliceTiming', hdr.Private_0019_1029./1000,...
      'NumberOfVolumesDiscardedByScanner', ' ',...
      'NumberOfVolumesDiscardedByUser', 10,...
      'DelayTime', ' ',...
      'FlipAngle', hdr.FlipAngle,...
      'MultibandAccelerationFactor', ' ',...
      'Instructions', ' ',...
      'TaskDescription', ' ',...
      'CogAtlasID', ' ',...
      'CogPOID', ' ',...
      'InstitutionName',hdr.InstitutionName,...
      'InstitutionAddress',hdr.InstitutionAddress);
      bold_json_str = jsonencode(bold_json);
      output = sprintf('%s/sub-%02d_task-%s_run-01_bold.json',D.func,id,Data.fileMapping.taskName{ix});
      fid = fopen(output, 'w');
      if fid == -1, error('Cannot create JSON file'); end
      fwrite(fid, bold_json_str, 'char');
      fclose(fid);
  end

 
  
  % (12) construct task onset file 
  headers = {'onset' 'duration'};
for r = Data.fileMapping.PREFolder'
    ix = c3nl.strDetect(fn,sprintf('%s/',r{1}));
    tmp = Data.onsets(Data.onsets.Task==Data.fileMapping.taskName{ix},:);
    T = table(tmp.Time./1000,tmp.Dur./1000,'VariableNames',headers);
output = sprintf('%s/sub-%02d_task-%s_run-01_events.txt',D.func,id,Data.fileMapping.taskName{ix});
    writetable(T,output,'Delimiter','tab');
    movefile(output,[output(1:end-3) 'tsv']);
end
else 
 % (13) construct demographics BIDS file for the entire study 
  d = new.folder([],in,{'PRE','LOG'});
  fn = c3nl.select('pth',d.LOG,'name','*.mat');
  T = table();
  for r = 1:numel(fn)
      load(log{r});
      hdr = Data.MPRAGE.MPRAGE.fullhdr;
      subj =strsplit(fn{r},'/');subj=subj{end-1};

  end

end
end
