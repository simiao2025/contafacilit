export enum TaxAnnex {
    I = 'I',
    II = 'II',
    III = 'III',
    IV = 'IV',
    V = 'V',
}

export interface TaxBracket {
    limit: number;
    nominalRate: number;
    deduction: number;
}

export interface AnnexRules {
    annex: TaxAnnex;
    brackets: TaxBracket[];
}

export interface TaxCalculationInput {
    revenueMonth: number;
    rbt12: number;
    folha12: number;
    defaultAnnex: TaxAnnex; // Geralmente III ou V para serviços
    isFatorRApplicable: boolean;
}

export interface TaxCalculationOutput {
    annexApplied: TaxAnnex;
    rbt12: number;
    fatorR: number | null;
    bracketEnqueued: number;
    nominalRate: number;
    deduction: number;
    effectiveRate: number;
    taxAmount: number;
}
