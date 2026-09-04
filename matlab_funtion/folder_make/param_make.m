file_content = fileread([new_folder,'param.opt']);
file_content = strrep(file_content, 'llmex', num2str(grid.LLm));
file_content = strrep(file_content, 'mmmex', num2str(grid.MMm));
file_content = strrep(file_content, 'nex', num2str(grid.N));
file_content = strrep(file_content, 'npei_ex', num2str(NP_XI));
file_content = strrep(file_content, 'npeta_ex', num2str(NP_ETA));

% Write the modified content back to the file
fid = fopen([new_folder,'param.opt'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);