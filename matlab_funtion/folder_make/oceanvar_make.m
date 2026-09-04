file_content = fileread([new_folder,'ocean_vars.opt']);
file_content = strrep(file_content, 'RST_STEP', num2str(time_stepping.rst));
file_content = strrep(file_content, 'HIS_STEP', num2str(time_stepping.his));
file_content = strrep(file_content, 'AVG_STEP', num2str(time_stepping.avg));

% Write the modified content back to the file
fid = fopen([new_folder,'ocean_vars.opt'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);