const weekDays = [
    { day: "Mo" },
    { day: "Tu" },
    { day: "We" },
    { day: "Th" },
    { day: "Fr" },
    { day: "Sa" },
    { day: "Su" },
]

function getDateInXMonthsTime(x) {
    const currentDate = new Date();
    if (x === 0) return currentDate;

    let targetMonth = currentDate.getMonth() + x;
    let targetYear = currentDate.getFullYear();
    targetYear += Math.floor(targetMonth / 12);
    targetMonth = (targetMonth % 12 + 12) % 12;

    return new Date(targetYear, targetMonth, 1);
}

function getCalendarLayout(dateObject, highlight) {
    if (!dateObject) dateObject = new Date();

    const today = new Date();
    const month = dateObject.getMonth();
    const year = dateObject.getFullYear();
    const firstOfMonth = new Date(year, month, 1);
    const mondayFirstOffset = (firstOfMonth.getDay() + 6) % 7;
    const firstShownDate = new Date(year, month, 1 - mondayFirstOffset);

    const calendar = [...Array(6)].map(() => Array(7));
    for (let row = 0; row < 6; row++) {
        for (let column = 0; column < 7; column++) {
            const date = new Date(firstShownDate);
            date.setDate(firstShownDate.getDate() + row * 7 + column);

            const inViewedMonth = date.getMonth() === month;
            const isToday = highlight
                && date.getDate() === today.getDate()
                && date.getMonth() === today.getMonth()
                && date.getFullYear() === today.getFullYear();

            calendar[row][column] = {
                day: date.getDate(),
                today: isToday ? 1 : (inViewedMonth ? 0 : -1),
            };
        }
    }

    return calendar;
}
