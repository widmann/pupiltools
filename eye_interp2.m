function [ EYE ] = eye_interp2( EYE, varargin )
% Interpolate marked regions
% Copyright (c) 2021 Andreas Widmann, University of Leipzig
% Author: Andreas Widmann, widmann@uni-leipzig.de

Arg = struct( varargin{ : } );

if ~isfield( Arg, 'chan' )
    error( 'Not enough input arguments' )
end

if ~isfield( Arg, 'extrapol' ) || isempty( Arg.extrapol )
    Arg.extrapol = 0;
end

if ~isfield( Arg, 'warning' ) || isempty( Arg.warning )
    Arg.warning = 1;
end
if Arg.warning
    warning( 'This function is work in progress. Do not use for productive purposes!')
end

% Find invalid data
valArray = ~isnan( EYE.data( Arg.chan, : ) );

% Find valid sections
valSectArray = [];
valSectArray( :, 1 ) = find( diff( [0 valArray ] ) == 1 );
valSectArray( :, 2 ) = find( diff( [valArray 0 ] ) == -1 );
valSectDur = valSectArray( :, 2 ) - valSectArray( :, 1 ) + 1;

valDistArray( :, 1 ) = valSectArray( :, 1 ) - [ 0; valSectArray( 1:end - 1, 2 ) ];
valDistArray( :, 2 ) = [ valSectArray( 2:end, 1 ); EYE.pnts + 1 ] - valSectArray( :, 2 );
if valDistArray( 1, 1 ) > 1, valDistArray( 1, 1 ) = inf; end
if valDistArray( end, 2 ) > 1, valDistArray( end, 2 ) = inf; end
[ valSectArray valSectDur valDistArray ]

% Remove sections shorter than minVal
isShort = find( valSectDur < Arg.minValDur );
isShortNeighbour = find( diff( isShort ) == 1 );
if ~isempty( isShortNeighbour )
    valDistArray( isShort( isShortNeighbour ), 2 ) = inf;
    valDistArray( isShort( isShortNeighbour ) + 1, 1 ) = inf;
end
for iSegm = 1:length( isShort )
    isShort( iSegm )
    if all( valDistArray( isShort( iSegm ), : ) > Arg.minValDist )
        EYE.data( Arg.chan, valSectArray( isShort( iSegm ), 1 ):valSectArray( isShort( iSegm ), 2 ) ) = NaN;
        fprintf( 'Removing short segment %d, dur %d, val dist pre %d, val dist pre %d\n', isShort( iSegm ), valSectDur( isShort( iSegm ) ), valDistArray( isShort( iSegm ), 1 ),valDistArray( isShort( iSegm ), 2 ) );
    end
end

invArray = isnan( EYE.data( Arg.chan, : ) );
    
% Find invalid sections
invSectArray = [];
invSectArray( :, 1 ) = find( diff( [0 invArray ] ) == 1 );
invSectArray( :, 2 ) = find( diff( [invArray 0 ] ) == -1 );
invSectDur = invSectArray( :, 2 ) - invSectArray( :, 1 ) + 1;

% Find sections to interpolate
if Arg.extrapol
    interpSectArray = invSectArray( invSectDur < Arg.maxInv, : );
else
    interpSectArray = invSectArray( invSectDur < Arg.maxInv & invSectArray( :, 1 ) ~= 1 & invSectArray( :, 2 ) ~= EYE.pnts, : );
end
interpIdx = [];
for iInterpSect = 1:size( interpSectArray, 1 )
    interpIdx = [ interpIdx interpSectArray( iInterpSect, 1 ):interpSectArray( iInterpSect, 2 ) ]; %#ok<AGROW>
end
if Arg.extrapol
    invSectArray( invSectDur < Arg.maxInv, : ) = [];
else
    invSectArray( invSectDur < Arg.maxInv & invSectArray( :, 1 ) ~= 1 & invSectArray( :, 2 ) ~= EYE.pnts, : ) = [];
end

% Interpolate data
% EYE.data( Arg.chan, interpIdx ) = interp1( setdiff( 1:EYE.pnts, interpIdx ), EYE.data( Arg.chan, setdiff( 1:EYE.pnts, interpIdx ) ), interpIdx, 'linear' );
EYE.data( Arg.chan, interpIdx ) = interp1( find( ~invArray ), EYE.data( Arg.chan, ~invArray ), interpIdx, 'pchip' );
if isfield( Arg, 'saveinterp' ) && ~isempty( Arg.saveinterp )
    EYE.data( Arg.saveinterp, interpIdx ) = 1;
end

EYE = eeg_eegrej( EYE, invSectArray );

end

