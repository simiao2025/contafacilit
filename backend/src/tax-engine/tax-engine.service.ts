import { Injectable } from '@nestjs/common';
import {
    TaxCalculationInput,
    TaxCalculationOutput,
    TaxAnnex,
    TaxBracket
} from './interfaces/tax-engine.interface';

@Injectable()
export class TaxEngineService {

    // Tabelas de alíquotas (Poderiam vir do motor_versions no futuro)
    private readonly annex3Brackets: TaxBracket[] = [
        { limit: 180000, nominalRate: 0.06, deduction: 0 },
        { limit: 360000, nominalRate: 0.112, deduction: 9360 },
        { limit: 720000, nominalRate: 0.135, deduction: 17640 },
        { limit: 1800000, nominalRate: 0.16, deduction: 35640 },
        { limit: 3600000, nominalRate: 0.21, deduction: 125640 },
        { limit: 4800000, nominalRate: 0.33, deduction: 648000 },
    ];

    private readonly annex5Brackets: TaxBracket[] = [
        { limit: 180000, nominalRate: 0.155, deduction: 0 },
        { limit: 360000, nominalRate: 0.18, deduction: 4500 },
        { limit: 720000, nominalRate: 0.195, deduction: 9900 },
        { limit: 1800000, nominalRate: 0.205, deduction: 17100 },
        { limit: 3600000, nominalRate: 0.23, deduction: 62100 },
        { limit: 4800000, nominalRate: 0.305, deduction: 540000 },
    ];

    /**
     * Calcula o imposto de forma determinística
     */
    calculate(input: TaxCalculationInput): TaxCalculationOutput {
        const { revenueMonth, rbt12, folha12, isFatorRApplicable } = input;

        let annexToApply = input.defaultAnnex;
        let fatorR: number | null = null;

        // Lógica do Fator R
        if (isFatorRApplicable) {
            fatorR = rbt12 > 0 ? folha12 / rbt12 : 0;
            annexToApply = fatorR >= 0.28 ? TaxAnnex.III : TaxAnnex.V;
        }

        const brackets = annexToApply === TaxAnnex.III ? this.annex3Brackets : this.annex5Brackets;

        // Identifica a faixa
        const bracketIndex = this.findBracketIndex(rbt12, brackets);
        const bracket = brackets[bracketIndex];

        // Cálculo da Alíquota Efetiva: (RBT12 * AlíquotaNominal - ParcelaDeduzir) / RBT12
        // Se for a 1ª faixa, a efetiva é igual a nominal (evita divisão por zero se RBT12 for baixo, 
        // embora RBT12 na 1a faixa teoricamente pode ser 0)
        let effectiveRate: number;
        if (rbt12 === 0 || bracketIndex === 0) {
            effectiveRate = bracket.nominalRate;
        } else {
            effectiveRate = (rbt12 * bracket.nominalRate - bracket.deduction) / rbt12;
        }

        // O valor do imposto é Receita do Mês * Alíquota Efetiva
        const taxAmount = Number((revenueMonth * effectiveRate).toFixed(2));

        return {
            annexApplied: annexToApply,
            rbt12,
            fatorR: fatorR ? Number(fatorR.toFixed(4)) : null,
            bracketEnqueued: bracketIndex + 1,
            nominalRate: bracket.nominalRate,
            deduction: bracket.deduction,
            effectiveRate: Number(effectiveRate.toFixed(6)),
            taxAmount,
        };
    }

    private findBracketIndex(rbt12: number, brackets: TaxBracket[]): number {
        for (let i = 0; i < brackets.length; i++) {
            if (rbt12 <= brackets[i].limit) {
                return i;
            }
        }
        return brackets.length - 1; // Última faixa se exceder o limite
    }
}
