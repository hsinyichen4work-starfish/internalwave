file_content = fileread([new_folder,'cppdefs.opt']);

if do_dia
    file_content = strrep(file_content, '#undef DIAGNOSTICS', '#define DIAGNOSTICS'); 
else
    file_content = strrep(file_content, '#define DIAGNOSTICS', '#undef DIAGNOSTICS');
end
% Write the modified content back to the file
fid = fopen([new_folder,'cppdefs.opt'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);

if do_dia
    copyfile([example_folder,'diagnostics.opt'],new_folder)
    file_content = fileread([new_folder,'diagnostics.opt']);
    file_content = strrep(file_content, 'DIASTEP', num2str(time_stepping.dia));
end
% Write the modified content back to the file
fid = fopen([new_folder,'diagnostics.opt'], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);