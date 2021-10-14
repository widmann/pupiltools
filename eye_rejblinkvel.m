% eye_rejblinkvel() - Detect and mark blinks in pupil data by velocity
%                     threshold for rejection/interpolation
%
% Usage:
%   >> [ EYE ] = eye_rejblinkvel( EYE, 'key1', value1, 'key2', value2, 
%                                      'keyn', valuen );
%
%  Inputs:
%   EYE           - EEGLAB EEG structure
%   'chans'       - vector channel indices to process
%
%  Optional inputs:
%   'velthresh'   - velocity threshold {default 20}
%   'preint'      - interval in s to reject before blink {default 0.05}
%   'postint'     - interval in s to reject after blink {default 0.1}
%
% Outputs:
%   EYE       - EEGLAB EEG structure
%
% Author: Andreas Widmann, 2021
%
% See also:
%   eye_rejsigloss, eye_rejblinkeyelink, eye_interp

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

function [ EYE ] = eye_rejblinkvel( EYE, varargin )

if nargin < 3
    error( 'Not enough input arguments.' )
end

Arg = struct( varargin{ : } );

if ~isfield( Arg, 'chans' ) || isempty( Arg.chans )
    error( 'chans input argument is required.' )
end

% Defaults
if ~isfield( Arg, 'velthresh' ) || isempty( Arg.velthresh )
    Arg.velthresh = 20; % mm / sec
end
if ~isfield( Arg, 'preint' ) || isempty( Arg.preint )
    Arg.preint = 0.05; % sec
end
if ~isfield( Arg, 'postint' ) || isempty( Arg.postint )
    Arg.postint = 0.1; % sec
end

if isempty( EYE.reject.rejmanualE )
    EYE.reject.rejmanualE = zeros( size( EYE.data ) );
end

% Detect blinks
for iEye = 1:length( Arg.chans )

    vel = smoothvel( EYE.data( Arg.chans( iEye ), : )', EYE.srate )';
    
    interpArray = find( abs( vel ) > Arg.velthresh );
    
    for idx = 1:length( interpArray )
        blinkStart = max( [ 1 interpArray( idx ) - EYE.srate * Arg.preint ] );
        blinkEnd = min( [ interpArray( idx ) + EYE.srate * Arg.postint EYE.pnts ] );
        EYE.reject.rejmanualE( Arg.chans( iEye ), blinkStart:blinkEnd ) = 1;
    end
    
end

end

function v = smoothvel( x, fs )
% Adapted from vecvel.m by Ralf Engbert
%
% Ref:
%   Engbert, R., & Kliegl, R. (2003) Microsaccades uncover the orientation
%   of covert attention. Vision Research, 43, 1035-1045.

v = [ 0; ...
      ( x( 3 ) - x( 1 ) ) * fs / 2; ...
      ( x( 5:end ) + x( 4:end - 1 ) - x( 2:end - 3 ) - x( 1:end - 4 ) ) * fs / 6; ...
      ( x( end ) - x( end - 2 ) ) * fs / 2; ...
      0 ];

end
