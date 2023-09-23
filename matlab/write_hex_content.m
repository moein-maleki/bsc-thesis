function write_hex_content(filename, data_to_write, q)

    line_count = numel(data_to_write);
    fd          = fopen(filename,  'w');
    formatSpec = '0x%s,\n';
    for i = 1:line_count
        data_hex = bin2hex(num2bin(q, data_to_write(i)));
        fprintf(fd, formatSpec, data_hex);
    end
    
    fclose(fd);
   
end

