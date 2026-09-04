
file_content = fileread([new_folder,'do_joint.sh']);
file_content = strrep(file_content, 'EXAMPLE_OUTPUT', output_path);

% Write the modified content back to the file
fid = fopen([new_folder,'do_joint.sh'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);