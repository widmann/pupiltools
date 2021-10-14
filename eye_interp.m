% eye_interp() - Interpolate marked intervals in pupil data
%
% Usage:
%   >> [ EYE ] = eye_interp( EYE, 'key1', value1, 'key2', value2, 
%                            'keyn', valuen );
%
%  Inputs:
%   EYE           - EEGLAB EEG structure
%   'chans'       - vector channel indices to process
%
%  Optional inputs:
%   'saveinterp'  - vector channel indices to save rejmanualE for
%                   documentation of interpolated samples
%   'extrapol'    - flag extrapolate data in case of interpolation at
%                   signal ends {default 0}
%
% Outputs:
%   EYE       - EEGLAB EEG structure
%
% Note:
%   Interpolate blinks or signal loss intervals in pupil data marked in
%   EYE.reject.rejmanualE substructure with piecewise cubic hermite
%   polynomial interpolation (pchip).
%
% Author: Andreas Widmann, 2021
%
% See also:
%   eye_rejsigloss, eye_rejblinkeyelink

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

function [ EYE ] = eye_interp( EYE, varargin )

if nargin < 3
    error( 'Not enough input arguments.' )
end

Arg = struct( varargin{ : } );

if ~isfield( Arg, 'chans' ) || isempty( Arg.chans )
    error( 'chans input argument is required.' )
end

% Defaults
if ~isfield( Arg, 'extrapol' ) || isempty( Arg.extrapol )
    Arg.extrapol = 0;
end

cutStart = [];
cutEnd = [];

for iEye = 1:length( Arg.chans )
    
    dataIdx = find( ~EYE.reject.rejmanualE( Arg.chans( iEye ), : ) );
    
    EYE.data( Arg.chans( iEye ), dataIdx(1):dataIdx(end) ) = interp1( dataIdx, EYE.data( Arg.chans( iEye ), dataIdx ), dataIdx(1):dataIdx(end), 'pchip' );

    if isfield( Arg, 'saveinterp' ) && ~isempty( Arg.saveinterp )
        EYE.data( Arg.saveinterp( iEye ), : ) = EYE.reject.rejmanualE( Arg.chans( iEye ), : );
    end
    
    if dataIdx( 1 ) > 1
        cutStart = max( [ cutStart dataIdx( 1 ) ] );
    end
    if dataIdx( end ) < EYE.pnts
        cutEnd = min( [ cutEnd dataIdx( end ) ] );
    end
    
end

EYE.reject.rejmanualE( Arg.chans, : ) = zeros( size( EYE.reject.rejmanualE( Arg.chans, : ) ) );

if Arg.extrapol == 0
    if ~isempty( cutStart )
        EYE = eeg_eegrej( EYE, [ 1 cutStart - 1 ] );
    end
    if ~isempty( cutEnd )
        EYE = eeg_eegrej( EYE, [ cutEnd + 1 EYE.pnts] );
    end
end

end

