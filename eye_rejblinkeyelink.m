% eye_rejblinkeyelink() - Mark Eyelink detected blinks for
%                         rejection/interpolation
%
% Usage:
%   >> [ EYE ] = eye_rejblinkeyelink( EYE, 'key1', value1, 'key2', value2,
%                                     'keyn', valuen );
%
%  Inputs:
%   EYE       - EEGLAB EEG structure
%   'chans'   - vector channel indices to process
%   'nosacc'  - ['error'|'warning'] throw error or warning if no enclosing
%               saccade is found for blink {default: error}
%
% Outputs:
%   EYE       - EEGLAB EEG structure
%
% Note:
%   Find Eyelink blink and saccade events, do some basic consistency
%   checks, find saccades enclosing the blink events and mark blinks in
%   EYE.reject.rejmanualE substructure for later rejection or
%   interpolation.
%
% Author: Andreas Widmann, 2021
%
% See also:
%   eye_rejsigloss, eye_interp

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

function [ EYE ] = eye_rejblinkeyelink( EYE, varargin )

if nargin < 3
    error( 'Not enough input arguments.' )
end

Arg = struct( varargin{ : } );

if ~isfield( Arg, 'chans' ) || isempty( Arg.chans )
    error( 'chans input argument is required.' )
end
if ~isfield( Arg, 'nosacc' ) || isempty( Arg.nosacc )
    Arg.nosacc = 'error';
end

if isempty( EYE.reject.rejmanualE )
    EYE.reject.rejmanualE = zeros( size( EYE.data ) );
end

% Detect saccades
startSaccIdx = find( strcmp( 'STARTSACC', { EYE.event.type } ) );
endSaccIdx = find( strcmp( 'ENDSACC', { EYE.event.type } ) );

[ Sacc( 1:length( startSaccIdx ) ).start ] = EYE.event( startSaccIdx ).latency;
[ Sacc.eye ] = EYE.event( startSaccIdx ).eye;

for iEye = unique( [ Sacc.eye ] )

    if sum( [ Sacc.eye ] == iEye ) ~= sum( [ EYE.event( endSaccIdx ).eye ] == iEye )
        %         for iTmp = unique( [ Sacc.eye ] )
        %             fprintf( 'Eye %d saccade start latencies:', iTmp );
        %             [ Sacc( [ Sacc.eye ] == iTmp ).start ]
        %             fprintf( 'Eye %d saccade end latencies:', iTmp );
        %             [ EYE.event( endSaccIdx( [ EYE.event( endSaccIdx ).eye ] == iTmp ) ).latency ]
        %         end
        error( 'Number of STARTSACC events (%d) does not match number of ENDSACC events (%d) for eye %d.', sum( [ Sacc.eye ] == iEye ), length( endSaccIdx ), iEye )
    end

    [ Sacc( [ Sacc.eye ] == iEye ).end ] = EYE.event( endSaccIdx( [ EYE.event( endSaccIdx ).eye ] == iEye ) ).latency;

end

if any( [ Sacc.start ] > [ Sacc.end ] )
    error( 'Saccade end latency < start latency.' )
end

EYE.etc.Sacc = Sacc;

% Detect blinks
startBlinkIdx = find( strcmp( 'STARTBLINK ', { EYE.event.type } ) );
endBlinkIdx = find( strcmp( 'ENDBLINK', { EYE.event.type } ) );

if ~isempty( startBlinkIdx )
    [ Blink( 1:length( startBlinkIdx ) ).start ] = EYE.event( startBlinkIdx ).latency;
    [ Blink.eye ] = EYE.event( startBlinkIdx ).eye;
else
    return
end

for iEye = unique( [ Blink.eye ] )

    if sum( [ Blink.eye ] == iEye ) ~= sum( [ EYE.event( endBlinkIdx ).eye ] == iEye )
                for iTmp = unique( [ Blink.eye ] )
%                     [ Sacc( [ Sacc.eye ] == iTmp ).start; Sacc( [ Sacc.eye ] == iTmp ).end ]
                    fprintf( 'Eye %d blink start latencies:', iTmp );
                    [ Blink( [ Blink.eye ] == iTmp ).start ]
                    fprintf( 'Eye %d blink end latencies:', iTmp );
                    [ EYE.event( endBlinkIdx( [ EYE.event( endBlinkIdx ).eye ] == iTmp ) ).latency ]
                end
        error( 'Number of STARTBLINK events (%d) does not match number of ENDBLINK events (%d) for eye %d. %d', sum( [ Blink.eye ] == iEye ), sum( [ EYE.event( endBlinkIdx ).eye ] == iEye ), iEye )
    end

    [ Blink( [ Blink.eye ] == iEye ).end ] = EYE.event( endBlinkIdx( [ EYE.event( endBlinkIdx ).eye ] == iEye ) ).latency;

end


if any( [ Blink.start ] > [ Blink.end ] )
    error( 'Blink end latency < start latency.' )
end

for iBlink = 1:length( Blink )

    saccIdx = find( [ Sacc.start ] < Blink( iBlink ).start & [ Sacc.eye ] == Blink( iBlink ).eye, 1, 'last' );

    if isempty( saccIdx )
        saccIdx = find( [ Sacc.start ] <= Blink( iBlink ).start & [ Sacc.eye ] == Blink( iBlink ).eye, 1, 'last' );
        if ~isempty( saccIdx )
            warning( 'STARTBLINK latency equals STARTSACC latency for blink #%d, start latency %d, end latency %d, eye %d.', iBlink, Blink( iBlink ).start, Blink( iBlink ).end, Blink( iBlink ).eye )
        end
    end

    if ~isempty( saccIdx )
        if Sacc( saccIdx ).end < Blink( iBlink ).end
            Blink( iBlink )
            Sacc( saccIdx )
            error( 'ENDSACC < ENDBLINK latency.' )
        end

        Blink( iBlink ).STARTSACC = Sacc( saccIdx ).start;
        Blink( iBlink ).ENDSACC = Sacc( saccIdx ).end;
        EYE.reject.rejmanualE( Arg.chans( Blink( iBlink ).eye ), Blink( iBlink ).STARTSACC:Blink( iBlink ).ENDSACC ) = 1;
    else
        msg = sprintf( 'No saccade found for blink #%d, start latency %d, end latency %d, eye %d.', iBlink, Blink( iBlink ).start, Blink( iBlink ).end, Blink( iBlink ).eye );
        if strcmp( Arg.nosacc, 'error' )
            error( msg )
        else
            warning( msg )
            EYE.reject.rejmanualE( Arg.chans( Blink( iBlink ).eye ), Blink( iBlink ).start:Blink( iBlink ).end ) = 1;
        end
    end

end

EYE.etc.Blink = Blink;

end

