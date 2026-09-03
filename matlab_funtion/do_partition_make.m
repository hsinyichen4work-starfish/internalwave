file_content = fileread([new_folder,'do_partition.sh']);
file_content = strrep(file_content, 'EXAMPLE_INPUT', '/expanse/lustre/projects/uso101/hchen54/input/');
file_content = strrep(file_content, 'npxi_ex', num2str(NP_XI));
file_content = strrep(file_content, 'npeta_ex', num2str(NP_ETA));
file_content = strrep(file_content, 'tag_ex', TAG_USE);

% Write the modified content back to the file
fid = fopen([new_folder,'do_partition.sh'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);

file_content = fileread([new_folder,'partition_input']);
file_content = strrep(file_content, 'FGRDEX', input_folder.grd);
file_content = strrep(file_content, 'FINIEX', input_folder.ini);
file_content = strrep(file_content, 'FBRYEX', input_folder.bry);
file_content = strrep(file_content, 'FFRCEX', input_folder.frc);

file_content = strrep(file_content, 'GRDEX', input_filenames.grd);
file_content = strrep(file_content, 'INIEX', input_filenames.ini);
file_content = strrep(file_content, 'BRYEX', input_filenames.bry);
file_content = strrep(file_content, 'FRCEX', input_filenames.frc);

% Write the modified content back to the file
fid = fopen([new_folder,'partition_input'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);