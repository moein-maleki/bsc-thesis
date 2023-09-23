% ------------------------------------------------------
% Title: formfilter.m
%
% Author: David Valencia
%
% Institution: UPIITA-IPN 2010
%
% for DSPrelated.com
% 
% Published in: http://www.dsprelated.com/showcode/12.php
%
% Description: This program receives 2 basic ortogonal
%               filters (one is high-pass and one is low-pass) 
%               the filtering level and the branch number.
%               As a result it returns the equivalent filter
%               of the specified branch.
% 
% Dependencies: upsample2.m
% http://www.dsprelated.com/showcode/10.php
%
% Revision: v1.0a
% - Commented and translated in English
%
% For more details on this code and its implementation
% see the following blog posts:
%
% http://www.dsprelated.com/showarticle/115.php
% http://www.dsprelated.com/showarticle/116.php
%
% ------------------------------------------------------

function [hx] = formfilter(n_stages,branch,h0,h1)
p = branch;

% Seed vector
hx = 0;
hx(1) = 1;

switch n_stages
    case 1
        % If it is a single stage filter
        % the branches are just the base filters
        if mod(branch,2) ~= 0
            hx = h0;
        else
            hx = h1;
        end
    case 2
        % For a 2 stage filter bank, the
        % equivalent filters are simply 
        % the convolution between the corresponding
        % base filters, and one of them is upsampled
        % The use of upsample2 is needed to avoid having
        % a large quantitiy of zeros at the end of the vector
        % which certainly difficults its usage to build a
        % convolution matrix.
        switch branch
            case 1
                hx = conv(h0,upsample2(h0,2));
            case 2
                hx = conv(h0,upsample2(h1,2));
            case 3
                hx = conv(h1,upsample2(h0,2));
            case 4
                hx = conv(h1,upsample2(h1,2));
            otherwise
                beep;
                fprintf('\nFor a 2 stage filter bank there can not be a fifth branch');
        end
        
    otherwise
        % For a n>2 stages filter bank, a more ellaborated
        % process must be made. A series of upsamplings and convolutions
        % are needed to get an equivalent vector.
        for i=0:n_stages-2
            q = floor(p /(2^(n_stages-1-i)));
            if (q == 1)
                hx = conv(hx,upsample2(h1,2^i));
            else
                hx = conv(hx,upsample2(h0,2^i));
            end
            p = mod(p,2^(n_stages-1-i));
        end
        
        % Depending on the parity of the branch number, the filter 
        % goes through a last convolution
        t = mod(branch,2);
        if(t == 1)
            hx = conv(hx,upsample2(h0,2^(n_stages-1)));
        else
            hx = conv(hx,upsample2(h1,2^(n_stages-1)));
        end
             
end