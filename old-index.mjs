import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const isYoga = await ask.ask(
    `Are you Yoga?`,
    ask.yesno
);
const who = isRose ? 'Rose' : 'Zack';

console.log(`Starting Morra Game! as ${who}`);

let acc = null;
const createAcc = await ask.ask(
    `Would you like to create an account? (only possible on devnet)`,
    ask.yesno
);
if (createAcc) {
    acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
} else {
    const secret = await ask.ask(
        `What is your account secret?`,
        (x => x)
    );
    acc = await stdlib.newAccountFromSecret(secret);
}

let ctc = null;
if (isYoga) {
    ctc = acc.contract(backend);
    ctc.getInfo().then((info) => {
        console.log(`The contract is deployed as = ${JSON.stringify(info)}`); });
} else {
    const info = await ask.ask(
        `Please paste the contract information:`,
        JSON.parse 
    );
    ctc = acc.contract(backend, info);
}

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async () => fmt(await stdlib.balanceOf(acc));

const before = await getBalance();
console.log(`Your balance is ${before}`);

const interact = { ...stdlib.hasRandom};

interact.informTimeout = () => {
    console.log(`There was a timeout.`);
    process.exit(1);
};

if (isYoga) {
    const amount = await ask.ask(
        `How much do you want to wager?`,
        stdlib.parseCurrency
    );
    interact.wager = amount;
    interact.deadline = { ETH: 100, ALGO: 100, CFX: 1000 }[stdlib.connector]; 
} else {
    interact.acceptWager = async (amount) => {
        const accepted = await ask.ask(
            `Do you accept the wager of ${fmt(amount)}?`,
            ask.yesno
        );
        if (!accepted) {
            process.exit(0);
        }
    };
}

const  HAND = ['0', '1', '2', '3', '4', '5'];
const GUESS = {
    '0': 0,  'Zero': 0,  'zero': 0,
    '1': 1,  'One': 1,   'one': 1,
    '2': 2,  'Two': 2,   'two': 2,
    '3': 3,  'Three': 3, 'three': 3,
    '4': 4,  'Four': 4,  'four': 4,
    '5': 5,  'Five': 5,  'five': 5,
    '6': 6,  'Six': 6,   'six': 6,
    '7': 7,  'Seven': 7, 'seven': 7,
    '8': 8,  'Eight': 8, 'eight': 8,
    '9': 9,  'Nine': 9,  'nine': 9,
    '10': 10, 'Ten': 10,  'ten': 10,
};

interact.getHand = async () => {
    const hand = await ask.ask(`What hand will you play?`, (x) => {
        const hand = GUESS[x];
        if ( hand === undefined ) {
            throw Error(`Not a valid hand ${hand}`);
        }
        return hand;
    });
    console.log(`You played ${HAND[hand]}`);
    return hand;
};

interact.getGuess = async () => {
    const guess = await ask.ask(`Predict you final answer.`, (x) => {
        const guess = GUESS[x];
        if (guess == undefined) {
            throw Error(`Not a valid hand ${guess}`);
        }
        return guess;
    });
    console.log(`You played ${GUESS[guess]}`);
    return guess;
}

const RESULT = ['Yoga wins', 'Draw', 'Zack wins'];
interact.seeOutcome = async (result) => {
    console.log(`The result is: ${RESULT[result]}`);
};

const part = isYoga ? ctc.p.Yoga : ctc.p.Zack;
await part(interact);

const after = await getBalance();
console.log(`You balance is now ${after}`);

ask.done();
