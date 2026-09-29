
file_content = fileread([new_folder,'joint_multi_job']);
file_content = strrep(file_content, 'EXAMPLE_OUTPUT', output_fold);

% Write the modified content back to the file
fid = fopen([new_folder,'joint_multi_job'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);


file_content = fileread([new_folder,'joint_output_record.sh']);
file_content = strrep(file_content, 'EXAMPLE_OUTPUT', output_fold);

% Write the modified content back to the file
fid = fopen([new_folder,'joint_output_record.sh'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);