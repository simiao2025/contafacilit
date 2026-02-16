import { Test, TestingModule } from '@nestjs/testing';
import { TaxEngineService } from './tax-engine.service';
import { TaxAnnex } from './interfaces/tax-engine.interface';

describe('TaxEngineService', () => {
    let service: TaxEngineService;

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [TaxEngineService],
        }).compile();

        service = module.get<TaxEngineService>(TaxEngineService);
    });

    describe('Cálculos de Serviços (TI/Engenharia) com Fator R', () => {

        it('deve tributar pelo ANEXO III se Fator R for >= 28% (Cenário: RBT12=100k, Folha12=30k)', () => {
            const result = service.calculate({
                revenueMonth: 10000,
                rbt12: 100000,
                folha12: 30000,
                defaultAnnex: TaxAnnex.V,
                isFatorRApplicable: true,
            });

            expect(result.annexApplied).toBe(TaxAnnex.III);
            expect(result.fatorR).toBe(0.3); // 30%
            expect(result.nominalRate).toBe(0.06); // 1ª faixa Anexo III
            expect(result.taxAmount).toBe(600); // 10000 * 0.06
        });

        it('deve tributar pelo ANEXO V se Fator R for < 28% (Cenário: RBT12=100k, Folha12=10k)', () => {
            const result = service.calculate({
                revenueMonth: 10000,
                rbt12: 100000,
                folha12: 10000,
                defaultAnnex: TaxAnnex.V,
                isFatorRApplicable: true,
            });

            expect(result.annexApplied).toBe(TaxAnnex.V);
            expect(result.fatorR).toBe(0.1); // 10%
            expect(result.nominalRate).toBe(0.155); // 1ª faixa Anexo V
            expect(result.taxAmount).toBe(1550); // 10000 * 0.155
        });

        it('deve calcular alíquota efetiva corretamente na 2ª faixa (Anexo III, RBT12=200k)', () => {
            // Cálculo manual: (200.000 * 11,20% - 9.360) / 200.000 = 0,0652 (6,52%)
            const result = service.calculate({
                revenueMonth: 20000,
                rbt12: 200000,
                folha12: 100000, // Alto Fator R
                defaultAnnex: TaxAnnex.III,
                isFatorRApplicable: true,
            });

            expect(result.annexApplied).toBe(TaxAnnex.III);
            expect(result.effectiveRate).toBe(0.0652);
            expect(result.taxAmount).toBe(1304); // 20000 * 0.0652
        });

        it('deve lidar com RBT12 = 0 (Novo negócio)', () => {
            const result = service.calculate({
                revenueMonth: 5000,
                rbt12: 0,
                folha12: 0,
                defaultAnnex: TaxAnnex.III,
                isFatorRApplicable: true,
            });

            expect(result.annexApplied).toBe(TaxAnnex.V); // Sem histórico de folha, cai no V se aplicável
            expect(result.nominalRate).toBe(0.155);
            expect(result.taxAmount).toBe(775);
        });
    });
});
