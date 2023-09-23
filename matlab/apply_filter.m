function filtred_signal = apply_filter(input_signal, filter_bank)

    input_signal_length = numel(input_signal);
    filter_length = length(filter_bank);
    signal_window = zeros(1, filter_length);
    filtred_signal = zeros(1, input_signal_length + filter_length - 1);

    input_signal = [input_signal, zeros(1, filter_length-1)];
    
    for edge_index = 1:(input_signal_length + filter_length - 1)
        signal_window(1) = input_signal(edge_index);
        tmp = 0;

        for i = 1:filter_length
            tmp  = tmp + signal_window(i) * filter_bank(i);
        end

        filtred_signal(edge_index) = tmp;

        for i = filter_length:-1:2
            signal_window(i) = signal_window(i-1);
        end

    end
        
end

