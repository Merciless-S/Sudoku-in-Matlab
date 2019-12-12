%%The main function of this program that create a single user game.
%%Load a sudoku template from the folder
%%and enable the user to play with it.
%% @author Jinze Yuan
function sudoku()
clc
clear
%load the data from the folder and store it as the sudoku.
user = input("what's the name of the template file? (default file: data.txt)", 's'); 
if ~strlength(user)
    user = "data.txt";
end
m = load(user);
%Check if the sudoku is valid and has at least one solution
if ~checkWhole(m) || ~solveSudoku(m)
    fprintf("\nThe sudoku is invalid.\n")
    return;
end
fprintf("\nYour Sudoku is valid\n")
%Declare a Java stack for undo operation
%Three digits number where stored into the stack, each digit refers to row,
%column, and the value in that cell.
stack =java.util.Stack();
%Create a copy of the template
%template = recordTemplate(m);
template = m(1:end, 1:end);
%Create a GUI object
my_scene = simpleGameEngine('retro_pack.png',16,16,5);
while 1
    %disp(m)
    makegraph(m,template,my_scene)
    %Check if the User have solved the sudoku.
    if isSolved(m)
        fprintf("*****You have solved the sudoku!*****\n***** Thanks for playing the game *****")
        return
    end
    %Prompt user for their option
    fprintf("\nChoice 1: Make a move\n")
    fprintf("Choice 2: Erase a cell\n")
    fprintf("Choice 3: Clear all\n")
    fprintf("Choice 4: Give me a hint\n")
    fprintf("Choice 5: Show me the solution\n")
    fprintf("Choice 6: Undo\n")
    fprintf("CHoice 7: quit\n")
    user = input("\nWhat do you want to do? (Enter a number)");
    %The case where the user wants to make a move
    clc
    if user == 1
        fprintf("Click on the a cell that you want to update\n")
        %Get the grid where the user with his cursor
        [x,y] = getMouseInput(my_scene);
        %Check if the cell user chose can be modified
        while template(x,y)
            fprintf("Invalid ceil\n")
            [x,y] = getMouseInput(my_scene);
        end
        %Print the avaibable number for user
        res = printAvai(m,x,y);
        if ~res
            continue
        end
        %Get the value user wants to choose
        k = input("\nEnter the value you choose (Enter -1 to quit): ");
        if k == -1
            continue
        end
        if k < 1 || k > 9
            fprintf("Invalid value\n")
            continue
        end
        %Update the value
        cur = m(x,y);
        [m,flag] = update(m,x,y,k,template);
        %If the update succeed, push it to the stack for later undo purpose
        if flag
            stack.push(x * 100 + y * 10 + cur);
            fprintf("Update success\n")
        else
            fprintf("Update fail. the sudoku remains the same\n")
        end
    %Case where the user choose to erase the cell
    elseif user == 2
        fprintf("Click on the a black cell to clear\n")
        [x,y] = getMouseInput(my_scene);
        while template(x,y)
            fprintf("Invalid ceil\n")
            [x,y] = getMouseInput(my_scene);
        end
        cur = m(x,y);
        %Remove that cell
        [m, flag] = remove(m,x,y,template);
        %If the update succeed, push it to the stack for later undo purpose
        if flag
            stack.push(x * 100 + y * 10 + cur);
            fprintf("Operation success\n")
        else
            fprintf("Cannot remove static value\n")
            continue
        end
    %Case where the user wants to clear the whole grid
    elseif user == 3
        m = template(1:end,1:end);
        stack.clear();
        fprintf("The sudoku is cleared\n")
    %Case where the user wants a hint
    elseif user == 4
        fprintf("Click on the a cell and I'll give you a hint\n")
        [x,y] = getMouseInput(my_scene);
        while template(x,y)
            fprintf("Invalid ceil\n")
            [x,y] = getMouseInput(my_scene);
        end
        %First solve the sudoku based on current grid
        [flag, solution] = solveSudoku(m);
        if flag
            %print the value on that specific cell
            fprintf("The value on (%i, %i) is %i\n", x,y, solution(x,y));
        else
            fprintf("Opps, it seems like you current grid is not solveable. Go back a few step and try again\n")
        end
    %Case where the user wants to solve the sudoku
    elseif user == 5
        %Solve the sudoku
        [flag, final] = solveSudoku(template);
         fprintf("The solution is here\n")
         showSolution(final, template)
    %case where the user wants to undo
    elseif user == 6
        %if stack is not empty, pop the latest number and restore the value
        %to the sudoku
        if(stack.size())
            value = stack.pop();
            x = floor(value / 100);
            y = mod(floor(value / 10), 10);
            k = mod(value, 10);
            m(x,y) = k;
            fprintf("Undo success\n")
        else
            fprintf("Cannot undo anymore.\n")
        end
    %Case where the user wants to quit the game
    elseif user == 7
        fprintf("Thanks for playing the game\n")
        break
    else
        fprintf("Not a valid option.\n")
    end
    pause(1)
end
end

%%This funciton create a graph of the sudoku for user.
function makegraph(m, template, scene)
graph = ones(9,9);
background = ones(9,9);
for i = 1:9
    for j = 1:9
        if m(i,j)
            graph(i,j) = m(i,j) + 948;
        end
        if template(i,j)
            background(i,j) = 169;
        end
    end
end
drawScene(scene,background,graph)
end

%Generate a new GUI with the solution to the sudoku to user
function showSolution(final, template)
graph = ones(9,9);
background = ones(9,9);
scene = simpleGameEngine('retro_pack.png',16,16,5);
for i = 1:9
    for j = 1:9
        if final(i,j)
            graph(i,j) = final(i,j) + 948;
        end
        if template(i,j)
            background(i,j) = 169;
        end
    end
end
%Draw the scene of the solution
drawScene(scene,background,graph)
end

%Check the whole grid and see if the sudoku obey the constrain
function res = checkWhole(m)
res = 1;
%Check if a single rows or column contains duplicate number
for i = 1:9
    row = zeros(9);
    column = zeros(9);
    for j = 1:9
        if (m(i,j) && row(m(i,j)) == 1) || (m(j,i) && column(m(j,i)) == 1)
            res = 0;
            return;
        end
        %check rows
        if m(i,j)
            row(m(i,j)) = 1;
        end
        %check columns
        if m(j,i)
            column(m(j,i)) = 1;
        end
    end
end
%Check if a 3*3 subgrid contains a deplicate number
for a = 3:3:9
    for b = 3:3:9
        seen = zeros(9);
        for i = a - 2:a
            for j = b - 2:b
                if m(i,j) && seen(m(i,j)) == 1
                    res = 0;
                    return
                end
                if m(i,j)
                    seen(m(i,j)) = 1;
                end
            end
        end
    end
end
end

%%This function use recursive Depth-First-Search algorithm to solve the
%%sudoku, where the flag indicate whether the sudoku could be solved or not
function [flag,m] = solveSudoku(m)
flag = 1;
for i = 1:9
    for j = 1:9
        if ~m(i,j)
            %Check which number is available
            arr = checkAvail(m,i,j);
            for k = 1:9
                if ~arr(k)
                    %First fill in that cell
                    m(i,j) = k;
                    %Continue searching
                    [flag, m] = solveSudoku(m);
                    %Found a solution
                    if flag
                        return;
                    end
                end
                %Erase that cell
                m(i,j) = 0;
            end
            %No solution found
            flag = 0;
            return
        end
    end
end
end

%%This function is used to check if a given cell has violate the constrains
%%of the sudoku. x and y refers to the row and column of that cell
function res = checkCell(m, x, y)
%%Check the row and columns
res = 1;
for i = 1:9
    if i ~= x && m(i,y) == m(x,y) || i ~= y && m(x,y) == m(x,i)
        res = 0;
        return;
    end
end
%%Check the 3*3 submatrix
for i = floor((x - 1)/3) * 3 + 1:floor((x - 1)/3) * 3 + 3
    for j = floor((y - 1)/3) * 3 + 1:floor((y - 1)/3) * 3 + 3
        if (i ~= x || j ~= y) && m(i,j) == m(x,y)
            res = 0;
            return;
        end
    end
end
end

%%This function return a boolean vector represent which number could be used
%%to fill in a specific cell. 0 refers to that number is available, 1 means
%%unavailable.
function arr = checkAvail(m,x,y)
arr = zeros(9,1);
%Check row and columns
for i = 1:9
    if i ~= x && m(i,y)
        arr(m(i,y)) = 1;
    end
    if i ~= y && m(x,i)
        arr(m(x,i)) = 1;
    end
end
%Check the 3*3 subgrid
for i = floor((x - 1)/3) * 3 + 1:floor((x - 1)/3) * 3 + 3
    for j = floor((y - 1)/3) * 3 + 1:floor((y - 1)/3) * 3 + 3
        if (i ~= x || j ~= y) && m(i,j)
            arr(m(i,j)) = 1;
        end
    end
end 
end

%%Print the number that are available to user in command window
function res = printAvai(m,x,y)
arr = checkAvail(m,x,y);
res = 1;
%Check if the vector has at least one zeros.
if sum(arr) == 9
    fprintf("This cell has no number available. You might want to undo several steps")
    res = 0;
    return
end
fprintf("The available number at this cell are:")
%Otherwise print the number that are avalable.
flag = 0;
for i = 1:9
    if ~arr(i)
        if ~flag
            flag = flag + 1;
        else
            fprintf(",")
        end
        fprintf("%d", i)
    end
end
end

%%Update a cell with the given value. Return True if update success, otherwise False
function [m,flag] = update(m, x, y, k, template)
%Check if it is a fixed value
if template(x,y)
    flag = 0;
    return;
end
temp = m(x,y);
m(x,y) =  k;
flag = 1;
%Check if it violate the constrains
if ~checkCell(m,x,y)
    flag = 0;
    m(x,y) = temp;
end
end

%%Clear a cell in the sudoku if it is not fixed. Return True if it is
%%removed, otherwise false
function [m,flag] = remove(m,x,y,template)
if ~template(x,y)
    flag = 1;
    m(x,y) = 0;
else
    flag = 0;
end
end

%%Check if the sudoku has no blank cells.
function flag = isSolved(m)
for i = 1:9
    for j = 1:9
        if ~m(i,j)
            flag = 0;
            return
        end
    end
end
end