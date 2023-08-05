outputs.normal= {'RtAeroCp', 'RtAeroCq', 'RtAeroCt', 'RtAeroFxh', 'RtAeroMxh', 'B1Fy'};
outputs.all= {'Cx', 'Cy', 'Cn', 'Ct', 'Cl', 'Cd', 'Phi', 'VRel', 'Alpha', 'Fx', 'Fy'};
af= aerodynAeroQSField(3:13, 0:22, '../example_data/sim/coh_URef-4_maininput.fst', outputs);

%%
% Fx= data.rho/2*repmat(permute(data.chord, [3 2 1]), size(af.Cx, 1), size(af.Cx, 2), 1).*af.Cx.*af.VRel.^2;
% Fy= data.rho/2*repmat(permute(data.chord, [3 2 1]), size(af.Cy, 1), size(af.Cy, 2), 1).*af.Cy.*af.VRel.^2;
% plot(1:19, squeeze(Fx(1, 1, :)), 1:19, squeeze(af.Fx(1, 1, :)))
Fx= af.Fx;
Fy= af.Fy;

dR= diff(data.R);
dRR= repmat(permute(dR, [3 2 1]), size(af.Cx, 1), size(af.Cx, 2), 1);

Fx_sect= (Fx(:, :, 1:end-1)+Fx(:, :, 2:end))/2 .* dRR;
Fxi= zeros(size(af.Cx, 1), size(af.Cx, 2), length(data.R));
Fxi(:, :, 1)= 0.5*Fx_sect(:, :, 1);
Fxi(:, :, 2:end-1)= 0.5*(Fx_sect(:, :, 1:end-1)+Fx_sect(:, :, 2:end));
Fxi(:, :, end)= 0.5*Fx_sect(:, :, end);
% RtFx= sum( Fxi, 3)*3;
% RtFx= reshape(trapz(data.R, reshape(Fx, numel(af.RtAeroFxh), [])'), size(af.RtAeroFxh))*3;

Fy_sect= (Fy(:, :, 1:end-1)+Fy(:, :, 2:end))/2 .* dRR;
Fyi= zeros(size(af.Cx, 1), size(af.Cx, 2), length(data.R));
Fyi(:, :, 1)= 0.5*Fy_sect(:, :, 1);
Fyi(:, :, 2:end-1)= 0.5*(Fy_sect(:, :, 1:end-1)+Fy_sect(:, :, 2:end));
Fyi(:, :, end)= 0.5*Fy_sect(:, :, end);
RtFy= reshape(trapz(data.R, reshape(Fy, numel(af.RtAeroCt), [])'), size(af.RtAeroCt))*3;

Mx_sect= reshape(int_torque_m(reshape(Fy, numel(af.RtAeroCt), []), data.R), size(af.Cx, 1), size(af.Cx, 2), length(data.R)-1)*3;
Mxi= zeros(size(af.Cx, 1), size(af.Cx, 2), length(data.R));
Mxi(:, :, 1)= 0.5*Mx_sect(:, :, 1);
Mxi(:, :, 2:end-1)= 0.5*(Mx_sect(:, :, 1:end-1)+Mx_sect(:, :, 2:end));
Mxi(:, :, end)= 0.5*Mx_sect(:, :, end);


%%
Fwind= data.rho/2 * pi*data.R(end)^2 * af.WindSpeed.^2;
FFwind= repmat(Fwind, 1, 1, length(data.R));
% RtCt= RtFx./Fwind;
RtCti= Fxi*3./FFwind;
assert(all((sum(RtCti, 3)-af.RtAeroCt)./af.RtAeroCt<2e-3, 'all'))

RtCsi= Fyi./FFwind;
assert(all((sum(Fyi, 3)-RtFy)./RtFy<2e-3, 'all'))

RtCmi= Mxi./FFwind/data.R(end);
assert(all((sum(RtCmi, 3)-af.RtAeroCq)./af.RtAeroCq<2e-3, 'all'))


