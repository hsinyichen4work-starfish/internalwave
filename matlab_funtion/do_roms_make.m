file_content = fileread([new_folder,'do_roms_expanse.sh']);
file_content = strrep(file_content, 'jobname_ex', fold_name);
file_content = strrep(file_content, 'NODEEX', num2str(node));
file_content = strrep(file_content, 'CPNEX', num2str(cpn));
file_content = strrep(file_content, 'NTASKEX', num2str(node*cpn));
file_content = strrep(file_content, 'WALLTIME_EX', walltime);
file_content = strrep(file_content, 'FILE_NAME_EX', filename);

% Write the modified content back to the file
fid = fopen([new_folder,'do_roms_expanse.sh'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);