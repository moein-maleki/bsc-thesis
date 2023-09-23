function write_bin_content(filename, data_to_write, q)

    line_count = numel(data_to_write);
    fd          = fopen(filename,  'w');
    formatSpec = '%s\n';
    for i = 1:line_count
        data_bin = num2bin(q, data_to_write(i));
        fprintf(fd, formatSpec, data_bin);
    end
    
    fclose(fd);
end

