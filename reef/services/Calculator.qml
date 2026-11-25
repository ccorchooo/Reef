pragma Singleton
import QtQuick
import Quickshell

// The Tools tab's calculator (parts/Island-Tools). Keys and typing build an expression;
// it's evaluated by a small parser here (+ − × ÷ ^ %, parentheses, unary minus), never
// by eval, so nothing typed can run.
//
//   Calculator.press("7"); Calculator.press("×"); Calculator.press("="); Calculator.result
Singleton {
    id: root

    property string expression: ""
    // The last evaluated expression, shown small above the result.
    property string previous: ""
    property string result: "0"
    // The operator just pressed (its key shows pressed until the next number).
    readonly property string pendingOperator: /[+−×÷]$/.test(expression) ? expression.slice(-1) : ""
    property bool _done: false

    readonly property var operators: ["+", "−", "×", "÷"]

    function press(key) {
        if (key === "=") {
            equals();
            return;
        }
        if (key === "C") {
            clear();
            return;
        }
        if (key === "⌫") {
            expression = expression.slice(0, -1);
            _done = false;
            _preview();
            return;
        }
        if (operators.includes(key) || key === "^" || key === "%") {
            // After =, keep going from the result.
            if (_done) {
                expression = result.replace("∞", "") || "0";
                previous = "";
                _done = false;
            }
            if (/[+−×÷^]$/.test(expression))
                expression = expression.slice(0, -1);
            if (expression === "" && key !== "−")
                expression = "0";
            expression += key;
            return;
        }
        // Digits, ".", parentheses: start over after =.
        if (_done) {
            expression = "";
            previous = "";
            _done = false;
        }
        expression += key;
        _preview();
    }

    // Typed keys: digits, operators (* / - + ^ %), parentheses, Enter, Backspace, Escape.
    function type(text) {
        const map = { "*": "×", "x": "×", "/": "÷", "-": "−", ",": "." };
        const k = map[text] ?? text;
        if (/^[0-9.()+−×÷^%]$/.test(k))
            press(k);
    }

    function equals() {
        if (expression === "")
            return;
        const v = evaluate(expression);
        if (v === null)
            return;
        previous = expression;
        result = format(v);
        _done = true;
    }

    function clear() {
        expression = "";
        previous = "";
        result = "0";
        _done = false;
    }

    // Live result while typing; the display keeps the last good one.
    function _preview() {
        const v = evaluate(expression);
        if (v !== null)
            result = format(v);
        else if (expression === "")
            result = "0";
    }

    function format(v) {
        if (!isFinite(v))
            return v > 0 ? "∞" : v < 0 ? "−∞" : "Not a number";
        const s = Math.abs(v) >= 1e12 || (v !== 0 && Math.abs(v) < 1e-9) ? v.toExponential(6) : String(Number(v.toPrecision(12)));
        return s.replace("-", "−");
    }

    // Shunting-yard over the display symbols. Returns null when incomplete or invalid.
    function evaluate(text) {
        const src = text.replace(/−/g, "-").replace(/×/g, "*").replace(/÷/g, "/");
        const tokens = src.match(/\d+\.?\d*(?:e[+-]?\d+)?|\.\d+|[-+*/^%()]/g);
        if (!tokens || tokens.join("") !== src.replace(/\s+/g, ""))
            return null;
        const prec = { "+": 1, "-": 1, "*": 2, "/": 2, "%": 2, "u": 3, "^": 4 };
        const right = { "^": true, "u": true };
        const out = [], ops = [];
        let expectValue = true;
        for (const t of tokens) {
            if (/^[\d.]/.test(t)) {
                if (!expectValue)
                    return null;
                out.push(parseFloat(t));
                expectValue = false;
            } else if (t === "(") {
                if (!expectValue)
                    return null;
                ops.push(t);
            } else if (t === ")") {
                if (expectValue)
                    return null;
                while (ops.length && ops[ops.length - 1] !== "(")
                    out.push(ops.pop());
                if (!ops.length)
                    return null;
                ops.pop();
            } else if (t === "%" && !expectValue) {
                // A percent sign after a number: divide it by 100.
                out.push(100, "/");
            } else {
                let op = t;
                if (expectValue) {
                    if (t !== "-")
                        return null;
                    op = "u";
                }
                while (ops.length) {
                    const top = ops[ops.length - 1];
                    if (top === "(" || !(prec[top] > prec[op] || (prec[top] === prec[op] && !right[op])))
                        break;
                    out.push(ops.pop());
                }
                ops.push(op);
                expectValue = true;
            }
        }
        if (expectValue)
            return null;
        while (ops.length) {
            const op = ops.pop();
            if (op === "(")
                return null;
            out.push(op);
        }
        const st = [];
        for (const t of out) {
            if (typeof t === "number") {
                st.push(t);
                continue;
            }
            if (t === "u") {
                st.push(-st.pop());
                continue;
            }
            const b = st.pop(), a = st.pop();
            if (a === undefined)
                return null;
            st.push(t === "+" ? a + b : t === "-" ? a - b : t === "*" ? a * b : t === "/" ? a / b : t === "%" ? a % b : Math.pow(a, b));
        }
        return st.length === 1 ? st[0] : null;
    }
}
