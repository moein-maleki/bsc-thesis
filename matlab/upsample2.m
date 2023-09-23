% David Valencia
% Posted @ DSPRelated.com
% in: http://www.dsprelated.com/showcode/10.php

function [y] = upsample2(x,N)

lx = length(x);
y = 0;

% Put first sample in the first position of the output

y(1) = x(1);

for i=2:lx
    % Create a "chunk" (or piece) of vector, composed
	% with a series of zeros and the next sample from
	% the input
	chunk = [zeros(1,N-1),x(i)];
	
	% Append the chunk to the current output vector
    y = [y,chunk];
end