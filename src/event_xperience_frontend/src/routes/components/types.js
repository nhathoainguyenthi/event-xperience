"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PurposeType = exports.ProposalType = void 0;
// types.ts
var ProposalType;
(function (ProposalType) {
    ProposalType["OTHER"] = "other";
    ProposalType["UPDATE"] = "codeUpdate";
    ProposalType["ADJUST"] = "adjustParameters";
    ProposalType["TRANSFER"] = "transferFunds";
})(ProposalType || (exports.ProposalType = ProposalType = {}));
var PurposeType;
(function (PurposeType) {
    PurposeType["TOFUND"] = "toFund";
    PurposeType["GRANT"] = "grantPayment";
    PurposeType["SERVICEBILL"] = "serviceBill";
})(PurposeType || (exports.PurposeType = PurposeType = {}));
//# sourceMappingURL=types.js.map