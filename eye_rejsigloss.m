% eye_rejsigloss() - Mark regions with signal loss in pupil data for
%                    rejection/interpolation
%
% Usage:
%   >> [ EYE ] = eye_rejsigloss( EYE, 'key1', value1, 'key2', value2, 
%                                     'keyn', valuen );
%
%  Inputs:
%   EYE       - EEGLAB EEG structure
%   'chans'   - vector channel indices to process
%
% Outputs:
%   EYE       - EEGLAB EEG structure
%
% Note:
%   Detect signal loss (zeros) in pupil data and mark in 
%   EYE.reject.rejmanualE substructure for later rejection or interpolation.
%
% Author: Andreas Widmann, 2021
%
% See also:
%   eye_interp

% Copyright (C) 2021 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function EYE = eye_rejsigloss( EYE, varargin )

if nargin < 3
    error( 'Not enough input arguments.' )
end

Arg = struct( varargin{ : } );

if ~isfield( Arg, 'chans' ) || isempty( Arg.chans )
    error( 'chans input argument is required.' )
end

if isempty( EYE.reject.rejmanualE )
    EYE.reject.rejmanualE = zeros( size( EYE.data ) );
end

EYE.reject.rejmanualE( Arg.chans, : ) = EYE.reject.rejmanualE( Arg.chans, : ) | EYE.data( Arg.chans, : ) == 0;

end

