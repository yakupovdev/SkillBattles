-- Full supplied SAT bank: 240 questions, 120 per discipline, 40 per difficulty.
-- Original prompts, explanations and 217 original choice sets are unchanged.
-- The owner authorized A-D conversion for 23 numeric-response Math questions.
-- authored_distractors=true identifies their three added wrong choices.
-- Source SHA-256 SAT_Questions_Math.md: cb779fb46ce96a132821f573fb044397fc61e5f91641b2b37d2203fd1372407d
-- Source SHA-256 SAT_Questions_RW.md: 9102ba7e7c8a663974fac00ebb5b795da620966321b4a2e02ac75cb71d0967f8
-- This migration only appends questions and merges catalogue topics; it never deletes rows.
CREATE TEMPORARY TABLE sat_question_seed ON COMMIT DROP AS
SELECT * FROM jsonb_to_recordset($sat_question_bank$
[
  {
    "id": "385a7c5a-ef42-5cb6-ab30-4edf27a36fbf",
    "external_key": "SAT_MATH:ac472881",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_ONE_VARIABLE",
    "topic_name": "Algebra / Linear equations in one variable",
    "difficulty": "HARD",
    "prompt": "$$\\frac{12x + 28}{4} - \\frac{s}{13} = r(x - 8)$$\n\nIn the given equation, $s$ and $r$ are constants, and $s > 0$. If the equation has infinitely many solutions, what is the value of $s$?",
    "options": [
      {
        "id": "5f3f1d4f-67b0-39a1-8e60-0d046c75cfcb",
        "key": "A",
        "text": "39"
      },
      {
        "id": "ed06cfba-1451-3424-8734-5f0f29c8884c",
        "key": "B",
        "text": "403"
      },
      {
        "id": "afca2330-a222-32c7-a60f-8dcecd13ea5b",
        "key": "C",
        "text": "104"
      },
      {
        "id": "b889edd6-0c54-3c1a-9106-69fc0a686239",
        "key": "D",
        "text": "416"
      }
    ],
    "correct_option_id": "ed06cfba-1451-3424-8734-5f0f29c8884c",
    "explanation": "The correct answer is 403. For a linear equation in one variable to have infinitely many solutions, the coefficients of the variable must be equal on both sides of the equation and the constant terms must also be equal on both sides of the equation. The given equation can be rewritten as:\n$$\\frac{4(3x + 7)}{4} - \\frac{s}{13} = r(x - 8)$$\nor\n$$3x + 7 - \\frac{s}{13} = r(x - 8)$$\nApplying the distributive property to the right-hand side of this equation yields:\n$$3x + 7 - \\frac{s}{13} = rx - 8r$$\nFor this equation to have infinitely many solutions, the coefficients of $x$ must be equal, so it follows that $3 = r$. Additionally, the constant terms must be equal, which means:\n$$7 - \\frac{s}{13} = -8r$$\nSubstituting $3$ for $r$ in this equation yields:\n$$7 - \\frac{s}{13} = -8(3) \\implies 7 - \\frac{s}{13} = -24$$\nAdding $\\frac{s}{13}$ to both sides yields:\n$$7 = -24 + \\frac{s}{13}$$\nAdding $24$ to both sides yields:\n$$31 = \\frac{s}{13}$$\nMultiplying both sides of this equation by $13$ yields:\n$$403 = s$$\nTherefore, if the equation has infinitely many solutions, the value of $s$ is 403.",
    "source_id": "ac472881",
    "source_number": 1,
    "authored_distractors": true
  },
  {
    "id": "7ca33bbc-f5b0-5d70-965f-b08f44dc23dc",
    "external_key": "SAT_MATH:3f5a3602",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "What system of linear equations is represented by the lines shown in the $xy$-plane?\n*(The graph shows two lines: one passing through $(8, 0)$ and $(3, 4)$, and the other passing through $(8, 0)$ and $(3, 2)$).*",
    "options": [
      {
        "id": "31d928db-d563-3e00-95f6-a9f4e7531747",
        "key": "A",
        "text": "$8x + 4y = 32$, $-10x - 4y = -64$"
      },
      {
        "id": "26baefc4-86a9-35fe-af63-f6508f20dee5",
        "key": "B",
        "text": "$8x - 4y = 32$, $-10x + 4y = -64$"
      },
      {
        "id": "f176b6fe-f5e5-3be4-839e-71e4adfcb6cd",
        "key": "C",
        "text": "$4x - 10y = 32$, $-8x + 10y = -64$"
      },
      {
        "id": "fac487a0-53b3-37a2-a440-bc2ebec8d05a",
        "key": "D",
        "text": "$4x + 10y = 32$, $-8x - 10y = -64$"
      }
    ],
    "correct_option_id": "fac487a0-53b3-37a2-a440-bc2ebec8d05a",
    "explanation": "Choice D is correct. A line in the $xy$-plane that passes through the points $(x_1, y_1)$ and $(x_2, y_2)$ has slope $m = \\frac{y_2 - y_1}{x_2 - x_1}$, and can be defined by an equation of the form $y - y_1 = m(x - x_1)$.\n\nOne of the lines shown in the graph passes through the points $(8, 0)$ and $(3, 4)$. Substituting $8$ for $x_1$, $0$ for $y_1$, $3$ for $x_2$, and $4$ for $y_2$ yields $m = \\frac{4 - 0}{3 - 8} = -\\frac{4}{5}$.\nSubstituting $-\\frac{4}{5}$ for $m$, $8$ for $x_1$, and $0$ for $y_1$ yields $y - 0 = -\\frac{4}{5}(x - 8)$, which is equivalent to $y = -\\frac{4}{5}x + \\frac{32}{5}$. Adding $\\frac{4}{5}x$ to both sides yields $\\frac{4}{5}x + y = \\frac{32}{5}$. Multiplying both sides by $-10$ yields $-8x - 10y = -64$.\n\nSimilarly, the other line shown in the graph passes through the points $(8, 0)$ and $(3, 2)$. Substituting $8$ for $x_1$, $0$ for $y_1$, $3$ for $x_2$, and $2$ for $y_2$ yields $m = \\frac{2 - 0}{3 - 8} = -\\frac{2}{5}$.\nSubstituting $-\\frac{2}{5}$ for $m$, $8$ for $x_1$, and $0$ for $y_1$ yields $y - 0 = -\\frac{2}{5}(x - 8)$, which is equivalent to $y = -\\frac{2}{5}x + \\frac{16}{5}$. Adding $\\frac{2}{5}x$ to both sides yields $\\frac{2}{5}x + y = \\frac{16}{5}$. Multiplying both sides by $10$ yields $4x + 10y = 32$.\n\nSo, the system of linear equations represented by the lines shown is $4x + 10y = 32$ and $-8x - 10y = -64$.\n\nChoices A, B, and C are incorrect and may result from conceptual or calculation errors.",
    "source_id": "3f5a3602",
    "source_number": 2,
    "authored_distractors": false
  },
  {
    "id": "c55cd529-492d-5981-8c22-32f4bb926043",
    "external_key": "SAT_MATH:edc1b7b7",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$2(8x) + 4(7y) = 12$$\n$$-2(8x) + 4(7y) = 12$$\n\nThe solution to the given system of equations is $(x, y)$. What is the value of $8x + 7y$?",
    "options": [
      {
        "id": "93866621-3e7c-3ba4-b0aa-fa62ad013f2e",
        "key": "A",
        "text": "1"
      },
      {
        "id": "5ccb3792-1a3e-3799-af99-1edfae029b66",
        "key": "B",
        "text": "6"
      },
      {
        "id": "46a590d8-9572-3dc5-9770-4c7def158094",
        "key": "C",
        "text": "9"
      },
      {
        "id": "9f5a1cb0-1968-32d5-b064-a8376d1b1e04",
        "key": "D",
        "text": "3"
      }
    ],
    "correct_option_id": "9f5a1cb0-1968-32d5-b064-a8376d1b1e04",
    "explanation": "The correct answer is 3. Adding the second equation to the first equation in the given system of equations yields:\n$$(2(8x) - 2(8x)) + (4(7y) + 4(7y)) = 12 + 12$$\n$$8(7y) = 24$$\nDividing both sides of this equation by $8$ yields $7y = 3$.\nSubstituting $3$ for $7y$ in the first equation, $2(8x) + 4(7y) = 12$, yields:\n$$2(8x) + 4(3) = 12 \\implies 2(8x) + 12 = 12$$\nSubtracting $12$ from both sides yields $2(8x) = 0$, so $8x = 0$.\nSubstituting $0$ for $8x$ and $3$ for $7y$ in the expression $8x + 7y$ yields $0 + 3 = 3$.\nTherefore, the value of $8x + 7y$ is 3.",
    "source_id": "edc1b7b7",
    "source_number": 3,
    "authored_distractors": true
  },
  {
    "id": "c108c118-457b-5e94-9ead-94ba0fe5a078",
    "external_key": "SAT_MATH:3008cfc3",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
    "topic_name": "Algebra / Linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "| $x$ | $y$ |\n| :---: | :---: |\n| $k$ | $13$ |\n| $k + 7$ | $-15$ |\n\nThe table gives the coordinates of two points on a line in the $xy$-plane. The $y$-intercept of the line is $(k - 5, b)$, where $k$ and $b$ are constants. What is the value of $b$?",
    "options": [
      {
        "id": "a06fc00b-8690-3e7b-9d93-a0ff00ccd03e",
        "key": "A",
        "text": "11"
      },
      {
        "id": "66db676a-9ab2-361b-8154-9ca41c6ec842",
        "key": "B",
        "text": "22"
      },
      {
        "id": "cc5532ca-e31d-3890-99c8-476a4f0d00e1",
        "key": "C",
        "text": "66"
      },
      {
        "id": "98655c83-1086-3039-834e-392df8b336c8",
        "key": "D",
        "text": "33"
      }
    ],
    "correct_option_id": "98655c83-1086-3039-834e-392df8b336c8",
    "explanation": "The correct answer is 33. It’s given in the table that the coordinates of two points on a line in the $xy$-plane are $(k, 13)$ and $(k + 7, -15)$. The slope $m$ of the line is:\n$$m = \\frac{-15 - 13}{(k + 7) - k} = \\frac{-28}{7} = -4$$\nIt's given that the $y$-intercept of the line is $(k - 5, b)$. Substituting $-4$ for $m$ and the coordinates $(k - 5, b)$ and $(k, 13)$ into the slope formula yields:\n$$-4 = \\frac{13 - b}{k - (k - 5)} = \\frac{13 - b}{5}$$\nMultiplying both sides of this equation by $5$ yields $-20 = 13 - b$.\nSubtracting $13$ from both sides yields $-33 = -b$, so $b = 33$.\nTherefore, the value of $b$ is 33.",
    "source_id": "3008cfc3",
    "source_number": 4,
    "authored_distractors": true
  },
  {
    "id": "91fd5980-f8c0-50aa-84db-1f31f9b7c7c8",
    "external_key": "SAT_MATH:4becad44",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$3x = 36y - 45$$\n\nOne of the two equations in a system of linear equations is given. The system has no solution. Which equation could be the second equation in this system?",
    "options": [
      {
        "id": "1f3155c3-1fb0-337a-b5db-3dc3e223b076",
        "key": "A",
        "text": "$x = 4y$"
      },
      {
        "id": "d96fcb2c-d2f3-3499-afd8-09bec637bd14",
        "key": "B",
        "text": "$\\frac{1}{3}x = 4y$"
      },
      {
        "id": "c3a9ef9d-f137-38a4-8390-835441dd951b",
        "key": "C",
        "text": "$x = 12y - 15$"
      },
      {
        "id": "b66cbcd6-5acc-3fe8-a30c-6199ec7d3771",
        "key": "D",
        "text": "$\\frac{1}{3}x = 12y - 15$"
      }
    ],
    "correct_option_id": "d96fcb2c-d2f3-3499-afd8-09bec637bd14",
    "explanation": "Choice B is correct. A system of two linear equations in two variables, $x$ and $y$, has no solution when the lines in the $xy$-plane representing the equations are parallel and distinct (same slope, different $y$-intercepts).\nThe given equation $3x = 36y - 45$ can be rewritten in slope-intercept form:\n$$36y = 3x + 45 \\implies y = \\frac{3}{36}x + \\frac{45}{36} = \\frac{1}{12}x + \\frac{5}{4}$$\nThe slope is $\\frac{1}{12}$ and the $y$-intercept is $(0, \\frac{5}{4})$.\nTherefore, the second equation must have slope $\\frac{1}{12}$ and a $y$-intercept other than $(0, \\frac{5}{4})$.\nMultiplying each side of the equation in choice B by $\\frac{1}{4}$ yields $\\frac{1}{12}x = y$, or $y = \\frac{1}{12}x$. This line has slope $\\frac{1}{12}$ and $y$-intercept $(0, 0)$. Since the slopes are equal and the $y$-intercepts are different, choice B produces a system with no solution.\n\nChoice A has slope $\\frac{1}{4}$, so it intersects the line in one point. Choice C is equivalent to the given equation (infinitely many solutions). Choice D has slope $\\frac{1}{36}$, so it intersects the line in one point.",
    "source_id": "4becad44",
    "source_number": 5,
    "authored_distractors": false
  },
  {
    "id": "8140461c-2659-5631-99e6-082fd0e85fd9",
    "external_key": "SAT_MATH:d1b66ae6",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$-x + y = -3.5$$\n$$x + 3y = 9.5$$\n\nIf $(x, y)$ satisfies the system of equations above, what is the value of $y$?",
    "options": [
      {
        "id": "6157f405-19cd-3931-89e0-690983d9d502",
        "key": "A",
        "text": "2/3"
      },
      {
        "id": "bf0e3845-3f73-3791-8c43-e5e325ca4461",
        "key": "B",
        "text": "3"
      },
      {
        "id": "494c811d-0965-34cb-9431-9897a6da66fd",
        "key": "C",
        "text": "**3/2** (or **1.5**)"
      },
      {
        "id": "87b812fc-40ba-361f-a01b-c12677ac3cf9",
        "key": "D",
        "text": "2"
      }
    ],
    "correct_option_id": "494c811d-0965-34cb-9431-9897a6da66fd",
    "explanation": "The correct answer is $\\frac{3}{2}$ (or $1.5$). Adding corresponding sides of the two equations:\n$$(-x + y) + (x + 3y) = -3.5 + 9.5$$\n$$4y = 6 \\implies y = \\frac{6}{4} = \\frac{3}{2} = 1.5$$",
    "source_id": "d1b66ae6",
    "source_number": 6,
    "authored_distractors": true
  },
  {
    "id": "f7db1bf4-1a53-544e-9dab-c0d9ca7c661d",
    "external_key": "SAT_MATH:9b7a1b67",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "The graph of line $h$ is shown in the $xy$-plane (passing through $(-6, 0)$ and $(0, -9)$). Line $k$ (not shown) is defined by $sx + 48y = t$, where $s$ and $t$ are constants. If line $k$ is graphed in this $xy$-plane, the result is a graph of two linear equations. This system of two linear equations has no solution. Which of the following is NOT a possible value of $t$?",
    "options": [
      {
        "id": "42253f5f-1470-3152-abd4-213c2a955ba9",
        "key": "A",
        "text": "$-432$"
      },
      {
        "id": "030d48bc-793c-38e7-a8e5-32b418ae7362",
        "key": "B",
        "text": "$-9$"
      },
      {
        "id": "f87f0aa5-57f8-3f8a-9e7b-1855188d7980",
        "key": "C",
        "text": "$72$"
      },
      {
        "id": "9ba378a1-cc74-3a8e-b823-cce5c13ec670",
        "key": "D",
        "text": "$288$"
      }
    ],
    "correct_option_id": "42253f5f-1470-3152-abd4-213c2a955ba9",
    "explanation": "Choice A is correct. Since the system has no solution, line $h$ and line $k$ must be parallel with different $y$-intercepts.\nThe $y$-intercept of line $h$ is $(0, -9)$.\nFor line $k$, substituting $x = 0$ into $sx + 48y = t$ gives $48y = t \\implies y = \\frac{t}{48}$, so its $y$-intercept is $(0, \\frac{t}{48})$.\nSince the two lines cannot have the same $y$-intercept:\n$$\\frac{t}{48} \\neq -9 \\implies t \\neq -9(48) = -432$$\nThus, $-432$ is NOT a possible value of $t$.\n\nChoice B is incorrect because $t = -9$ gives $y$-intercept $-\\frac{9}{48} \\neq -9$, which is possible. Choices C and D give $y$-intercepts different from $-9$, so they are possible values of $t$.",
    "source_id": "9b7a1b67",
    "source_number": 7,
    "authored_distractors": false
  },
  {
    "id": "6f46800b-34c8-5c7d-9a25-34b060e0f5ea",
    "external_key": "SAT_MATH:3cdbf026",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
    "topic_name": "Algebra / Linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "The graph of the equation $ax + ky = 6$ is a line in the $xy$-plane, where $a$ and $k$ are constants. If the line contains the points $(-2, -6)$ and $(0, -3)$, what is the value of $k$?",
    "options": [
      {
        "id": "2c2a0ae9-7d53-31de-b301-ba68204a38e5",
        "key": "A",
        "text": "$-2$"
      },
      {
        "id": "574654e5-90bc-3900-a385-3b9ed36c16c8",
        "key": "B",
        "text": "$-1$"
      },
      {
        "id": "0696c9f9-5cfa-39b7-95bc-27dcb71d6cd6",
        "key": "C",
        "text": "$2$"
      },
      {
        "id": "4ebe3740-e149-3045-8322-b1c037802e53",
        "key": "D",
        "text": "$3$"
      }
    ],
    "correct_option_id": "2c2a0ae9-7d53-31de-b301-ba68204a38e5",
    "explanation": "Choice A is correct. The equation $ax + ky = 6$ can be rewritten in slope-intercept form as:\n$$y = -\\frac{a}{k}x + \\frac{6}{k}$$\nThe $y$-intercept of the line is given as $(0, -3)$. Therefore, the $y$-coordinate of the $y$-intercept must be equal to $\\frac{6}{k}$:\n$$-3 = \\frac{6}{k} \\implies -3k = 6 \\implies k = -2$$\n\nChoices B, C, and D are incorrect and may result from errors made rewriting the given equation.",
    "source_id": "3cdbf026",
    "source_number": 8,
    "authored_distractors": false
  },
  {
    "id": "896fc3d0-5da9-523a-a6ff-60ca21a5d35b",
    "external_key": "SAT_MATH:00723d16",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
    "topic_name": "Algebra / Linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "Line $\\ell$ is defined by $3y + 12x = 5$. Line $n$ is perpendicular to line $\\ell$ in the $xy$-plane. What is the slope of line $n$?",
    "options": [
      {
        "id": "c6bb432a-2181-3a48-a688-4b187e9340f9",
        "key": "A",
        "text": "1/2"
      },
      {
        "id": "f61e9793-b090-3979-9a84-6ecb0b9faf21",
        "key": "B",
        "text": "3/4"
      },
      {
        "id": "c528c6fe-e07b-34e4-a878-f120b5db5d97",
        "key": "C",
        "text": "**1/4** (or **0.25**)"
      },
      {
        "id": "c15729b7-ab14-37eb-a634-d16f4b3d804c",
        "key": "D",
        "text": "4"
      }
    ],
    "correct_option_id": "c528c6fe-e07b-34e4-a878-f120b5db5d97",
    "explanation": "The correct answer is $\\frac{1}{4}$ (or $0.25$). For line $\\ell$, rewriting in slope-intercept form:\n$$3y = -12x + 5 \\implies y = -4x + \\frac{5}{3}$$\nThus, the slope of line $\\ell$ is $-4$.\nSince line $n$ is perpendicular to line $\\ell$, the slope of line $n$ is the negative reciprocal of $-4$:\n$$-\\frac{1}{-4} = \\frac{1}{4} = 0.25$$",
    "source_id": "00723d16",
    "source_number": 9,
    "authored_distractors": true
  },
  {
    "id": "9ffcc91e-3f90-5d78-b5df-d3cd665b00dd",
    "external_key": "SAT_MATH:ff501705",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$\\frac{3}{2}y - \\frac{1}{4}x = \\frac{2}{3} - \\frac{3}{2}y$$\n$$\\frac{1}{2}x + \\frac{3}{2} = py + \\frac{9}{2}$$\n\nIn the given system of equations, $p$ is a constant. If the system has no solution, what is the value of $p$?",
    "options": [
      {
        "id": "70976203-7a53-390b-a0d2-7b652072ea76",
        "key": "A",
        "text": "3"
      },
      {
        "id": "f7cfe211-9600-3938-9c92-30b3c87d3535",
        "key": "B",
        "text": "6"
      },
      {
        "id": "57af50a0-e861-38cc-aeab-f6298da14f1a",
        "key": "C",
        "text": "12"
      },
      {
        "id": "063b0def-afe2-35bc-a257-001532b4258c",
        "key": "D",
        "text": "18"
      }
    ],
    "correct_option_id": "f7cfe211-9600-3938-9c92-30b3c87d3535",
    "explanation": "The correct answer is 6. For a system of two linear equations to have no solution, the lines must be parallel and distinct.\nMultiplying the first equation by $12$:\n$$18y - 3x = 8 - 18y \\implies -3x + 36y = 8$$\nMultiplying the second equation by $2$:\n$$x + 3 = 2py + 9 \\implies x - 2py = 6$$\nFor the lines to be parallel, the coefficients of $x$ and $y$ must be proportional:\n$$\\frac{-3}{1} = \\frac{36}{-2p} \\implies -3 = -\\frac{18}{p} \\implies p = 6$$\nChecking constants: $\\frac{8}{6} = \\frac{4}{3} \\neq -3$, so the lines are distinct and parallel. Thus, $p = 6$.",
    "source_id": "ff501705",
    "source_number": 10,
    "authored_distractors": true
  },
  {
    "id": "53a79b58-52a5-5bac-8f64-28ba708fed88",
    "external_key": "SAT_MATH:2c6f214f",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "HARD",
    "prompt": "The first term of a sequence is $9$. Each term after the first is $4$ times the preceding term. If $w$ represents the $n$th term of the sequence, which equation gives $w$ in terms of $n$?",
    "options": [
      {
        "id": "e58dbd36-c4da-3658-bf77-e54919fee870",
        "key": "A",
        "text": "$w = 4(9^n)$"
      },
      {
        "id": "88b8509f-5d3a-30f4-a404-d42867d289bf",
        "key": "B",
        "text": "$w = 4(9^{n-1})$"
      },
      {
        "id": "94d3838d-d319-311e-9697-1ab0749490f2",
        "key": "C",
        "text": "$w = 9(4^n)$"
      },
      {
        "id": "a8a7d063-0486-36d7-a008-2aa31b12870d",
        "key": "D",
        "text": "$w = 9(4^{n-1})$"
      }
    ],
    "correct_option_id": "a8a7d063-0486-36d7-a008-2aa31b12870d",
    "explanation": "Choice D is correct. A geometric sequence with first term $a_1$ and common ratio $r$ has $n$th term $a_n = a_1 r^{n-1}$. Here, the first term is $9$ and each subsequent term is multiplied by $4$ (so $r = 4$). Therefore, $w = 9(4^{n-1})$.\n\nChoices A, B, and C are incorrect because they interchange the first term and common ratio or use an incorrect power index.",
    "source_id": "2c6f214f",
    "source_number": 11,
    "authored_distractors": false
  },
  {
    "id": "0099cdda-b721-57b4-bf1b-84c1bb035c25",
    "external_key": "SAT_MATH:781c2f6e",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "HARD",
    "prompt": "The function $f$ is defined by $f(x) = a(2.2^x + 2.2^b)$, where $a$ and $b$ are integer constants and $0 < a < b$. The functions $g$ and $h$ are equivalent to function $f$, where $k$ and $m$ are constants. Which of the following equations displays the $y$-coordinate of the $y$-intercept of the graph of $y = f(x)$ in the $xy$-plane as a constant or coefficient?\nI. $g(x) = a(2.2^x + k)$\nII. $h(x) = a(2.2)^x + m$",
    "options": [
      {
        "id": "901887c2-f382-3783-a486-8517ff112996",
        "key": "A",
        "text": "I only"
      },
      {
        "id": "04f9e6e0-5e18-3250-84d0-aeccf0dc2ff2",
        "key": "B",
        "text": "II only"
      },
      {
        "id": "38b77a9c-6909-3169-9cec-7f3358d770b6",
        "key": "C",
        "text": "I and II"
      },
      {
        "id": "b7dab223-e85d-3039-b95e-e2cb8fc97507",
        "key": "D",
        "text": "Neither I nor II"
      }
    ],
    "correct_option_id": "b7dab223-e85d-3039-b95e-e2cb8fc97507",
    "explanation": "Choice D is correct. The $y$-intercept occurs at $x = 0$:\n$$f(0) = a(2.2^0 + 2.2^b) = a(1 + 2.2^b) = a + a(2.2)^b$$\nFor equation I: $g(x) = a(2.2^x + k)$ is equivalent to $f(x)$ if $k = 2.2^b$. But the $y$-intercept is $a + a(2.2)^b$, which does not equal $k$ or $a$, since $0 < a < b$.\nFor equation II: $h(x) = a(2.2)^x + m$ is equivalent to $f(x)$ if $m = a(2.2)^b$. But the $y$-intercept is $a + a(2.2)^b$, which does not equal $m$ (it is $a + m$) and does not equal $a$.\nThus, neither function displays the $y$-intercept value $a + a(2.2)^b$ as a constant or coefficient.",
    "source_id": "781c2f6e",
    "source_number": 12,
    "authored_distractors": false
  },
  {
    "id": "2dfad090-6c11-50be-aef7-1373d83796bc",
    "external_key": "SAT_MATH:4661e2a9",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_EQUATIONS",
    "topic_name": "Advanced Math / Nonlinear equations in one variable and systems of equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$x - y = 1$$\n$$x + y = x^2 - 3$$\n\nWhich ordered pair is a solution to the system of equations above?",
    "options": [
      {
        "id": "1e391754-c23a-3caa-9892-97302f55b5cb",
        "key": "A",
        "text": "$(1 + \\sqrt{3}, \\sqrt{3})$"
      },
      {
        "id": "5f86fd4c-84a5-3b7d-bb43-1c5fea3e9ba9",
        "key": "B",
        "text": "$(\\sqrt{3}, -\\sqrt{3})$"
      },
      {
        "id": "b6988de9-ac1e-358f-bc6e-7ffbec322e09",
        "key": "C",
        "text": "$(1 + \\sqrt{5}, \\sqrt{5})$"
      },
      {
        "id": "f13249f4-2c1b-3952-aa24-42068e3e9b93",
        "key": "D",
        "text": "$(\\sqrt{5}, -1 + \\sqrt{5})$"
      }
    ],
    "correct_option_id": "1e391754-c23a-3caa-9892-97302f55b5cb",
    "explanation": "Choice A is correct. From the first equation, $x = y + 1$. Substituting into the second equation:\n$$(y + 1) + y = (y + 1)^2 - 3$$\n$$2y + 1 = y^2 + 2y + 1 - 3 = y^2 + 2y - 2$$\nSubtracting $2y$ from both sides:\n$$1 = y^2 - 2 \\implies y^2 = 3 \\implies y = \\pm \\sqrt{3}$$\nIf $y = \\sqrt{3}$, then $x = 1 + \\sqrt{3}$. Thus, $(1 + \\sqrt{3}, \\sqrt{3})$ is a solution.",
    "source_id": "4661e2a9",
    "source_number": 13,
    "authored_distractors": false
  },
  {
    "id": "ff3f95da-19f6-576f-b108-7c46721553d7",
    "external_key": "SAT_MATH:371cbf6b",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "HARD",
    "prompt": "$$(ax + 3)(5x^2 - bx + 4) = 20x^3 - 9x^2 - 2x + 12$$\n\nThe equation above is true for all $x$, where $a$ and $b$ are constants. What is the value of $ab$?",
    "options": [
      {
        "id": "586b4436-c848-310d-9c30-bf4af34b873c",
        "key": "A",
        "text": "18"
      },
      {
        "id": "74a1dae6-9548-3dba-9ec3-25e73ac92e5b",
        "key": "B",
        "text": "20"
      },
      {
        "id": "f611fc4d-775d-37e5-94c6-03fe69918596",
        "key": "C",
        "text": "24"
      },
      {
        "id": "245ec133-6082-3258-b2c6-52eba4650646",
        "key": "D",
        "text": "40"
      }
    ],
    "correct_option_id": "f611fc4d-775d-37e5-94c6-03fe69918596",
    "explanation": "Choice C is correct. Expanding the left-hand side:\n$$(ax + 3)(5x^2 - bx + 4) = 5ax^3 - abx^2 + 4ax + 15x^2 - 3bx + 12$$\n$$= 5ax^3 + (15 - ab)x^2 + (4a - 3b)x + 12$$\nEquating coefficients with $20x^3 - 9x^2 - 2x + 12$:\nFor $x^3$: $5a = 20 \\implies a = 4$.\nFor $x^2$: $15 - ab = -9 \\implies -ab = -24 \\implies ab = 24$.",
    "source_id": "371cbf6b",
    "source_number": 14,
    "authored_distractors": false
  },
  {
    "id": "953a1fe2-38f3-5944-969b-ae15ac5a33d8",
    "external_key": "SAT_MATH:c3b116d7",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "HARD",
    "prompt": "Which of the following expressions is(are) a factor of $3x^2 + 20x - 63$?\nI. $x - 9$\nII. $3x - 7$",
    "options": [
      {
        "id": "9e9f82eb-a4d0-3fac-aceb-3f5b021ed906",
        "key": "A",
        "text": "I only"
      },
      {
        "id": "bdc6c9c0-1385-3de3-86f8-4b362b4c82da",
        "key": "B",
        "text": "II only"
      },
      {
        "id": "0049dc0b-c3c8-3746-8337-39bddf834021",
        "key": "C",
        "text": "I and II"
      },
      {
        "id": "c1ea589d-a988-3f52-814d-f09fa2d7c779",
        "key": "D",
        "text": "Neither I nor II"
      }
    ],
    "correct_option_id": "bdc6c9c0-1385-3de3-86f8-4b362b4c82da",
    "explanation": "Choice B is correct. We factor $3x^2 + 20x - 63$:\nThe product of $a \\cdot c = 3(-63) = -189$, and the sum is $20$.\nTwo numbers that multiply to $-189$ and add to $20$ are $27$ and $-7$.\n$$3x^2 + 27x - 7x - 63 = 3x(x + 9) - 7(x + 9) = (3x - 7)(x + 9)$$\nTherefore, $3x - 7$ (Expression II) is a factor, while $x - 9$ (Expression I) is not a factor (the factor is $x + 9$).",
    "source_id": "c3b116d7",
    "source_number": 15,
    "authored_distractors": false
  },
  {
    "id": "4797d25a-0360-58d7-8e2c-3028c5767783",
    "external_key": "SAT_MATH:40c09d66",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "HARD",
    "prompt": "If $\\frac{\\sqrt{x^5}}{\\sqrt[3]{x^4}} = x^{a/b}$ for all positive values of $x$, what is the value of $\\frac{a}{b}$?",
    "options": [
      {
        "id": "8deef383-39a6-3325-a83a-8165e16726ec",
        "key": "A",
        "text": "6/7"
      },
      {
        "id": "c959c0c4-92b1-3b75-9198-080a7dafe016",
        "key": "B",
        "text": "7"
      },
      {
        "id": "c7b8b202-0270-3995-b10c-80cb7041c35f",
        "key": "C",
        "text": "**7/6** (or **1.166**, **1.167**)"
      },
      {
        "id": "e2673fac-6ef2-3a2a-aa25-3f58f07a7bfe",
        "key": "D",
        "text": "13/6"
      }
    ],
    "correct_option_id": "c7b8b202-0270-3995-b10c-80cb7041c35f",
    "explanation": "The correct answer is $\\frac{7}{6}$. Rewriting radicals in exponential form:\n$$\\sqrt{x^5} = x^{5/2}, \\quad \\sqrt[3]{x^4} = x^{4/3}$$\nUsing exponent division rules:\n$$\\frac{x^{5/2}}{x^{4/3}} = x^{(5/2 - 4/3)} = x^{(15/6 - 8/6)} = x^{7/6}$$\nTherefore, $\\frac{a}{b} = \\frac{7}{6}$.",
    "source_id": "40c09d66",
    "source_number": 16,
    "authored_distractors": true
  },
  {
    "id": "5d4646b9-cd10-52af-989f-4d43c4ca6fb4",
    "external_key": "SAT_MATH:b8f13a3a",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "HARD",
    "prompt": "Function $f$ is defined by $f(x) = -a^x + b$, where $a$ and $b$ are constants. In the $xy$-plane, the graph of $y = f(x) - 12$ has a $y$-intercept at $(0, -\\frac{75}{7})$. The product of $a$ and $b$ is $\\frac{320}{7}$. What is the value of $a$?",
    "options": [
      {
        "id": "82d68f27-3467-34fa-9f2f-144aed12b2a0",
        "key": "A",
        "text": "10"
      },
      {
        "id": "3ba9972f-9fb7-3a89-bcd7-c7668e17e171",
        "key": "B",
        "text": "25"
      },
      {
        "id": "31f91c6b-1b81-391c-b003-65bc2cfc2a8c",
        "key": "C",
        "text": "20"
      },
      {
        "id": "57569a3e-8416-38a4-8315-a11b3f1d0981",
        "key": "D",
        "text": "40"
      }
    ],
    "correct_option_id": "31f91c6b-1b81-391c-b003-65bc2cfc2a8c",
    "explanation": "The correct answer is 20. The function for the graph is:\n$$y = f(x) - 12 = -a^x + b - 12$$\nThe $y$-intercept occurs at $x = 0$, where $y = -\\frac{75}{7}$:\n$$-\\frac{75}{7} = -a^0 + b - 12 = -1 + b - 12 = b - 13$$\n$$b = 13 - \\frac{75}{7} = \\frac{91 - 75}{7} = \\frac{16}{7}$$\nIt is given that $a \\cdot b = \\frac{320}{7}$. Substituting $b = \\frac{16}{7}$:\n$$a\\left(\\frac{16}{7}\\right) = \\frac{320}{7} \\implies a = \\frac{320}{16} = 20$$",
    "source_id": "b8f13a3a",
    "source_number": 17,
    "authored_distractors": true
  },
  {
    "id": "c7d630c9-f39c-5761-9ac2-c1f14655aec1",
    "external_key": "SAT_MATH:8e1da169",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "HARD",
    "prompt": "$$f(x) = (x - 44)(x - 46)$$\n\nThe function $f$ is defined by the given equation. For what value of $x$ does $f(x)$ reach its minimum?",
    "options": [
      {
        "id": "ac8a24be-f900-38d4-8448-44d2652f0f63",
        "key": "A",
        "text": "$46$"
      },
      {
        "id": "14ea33f8-91a9-376d-9210-564a718a4ea0",
        "key": "B",
        "text": "$45$"
      },
      {
        "id": "c2711449-fe3d-31c1-a8b1-7c4e23a84206",
        "key": "C",
        "text": "$44$"
      },
      {
        "id": "89eb4806-9068-3dbf-a1bc-7b07caf94209",
        "key": "D",
        "text": "$-1$"
      }
    ],
    "correct_option_id": "14ea33f8-91a9-376d-9210-564a718a4ea0",
    "explanation": "Choice B is correct. The function $f(x) = (x - 44)(x - 46)$ is a quadratic function opening upward with $x$-intercepts at $x = 44$ and $x = 46$. The vertex (minimum) of a parabola lies exactly midway between its $x$-intercepts:\n$$x = \\frac{44 + 46}{2} = 45$$",
    "source_id": "8e1da169",
    "source_number": 18,
    "authored_distractors": false
  },
  {
    "id": "76bc9e95-cce1-5e53-a43f-32b8153a7135",
    "external_key": "SAT_MATH:46308566",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_EQUATIONS",
    "topic_name": "Advanced Math / Nonlinear equations in one variable and systems of equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$r^2 + qr = 2r - 55$$\n\nIn the given equation, $q$ is an integer constant. The given equation has no real solutions. What is the largest possible value of $q$?",
    "options": [
      {
        "id": "fb4e9828-b7cf-3676-924d-43cc10ea056e",
        "key": "A",
        "text": "8"
      },
      {
        "id": "2c561ff3-a458-3074-a2da-62d10e906e68",
        "key": "B",
        "text": "24"
      },
      {
        "id": "bf78b14f-93d9-35ff-8e35-563a282d3de4",
        "key": "C",
        "text": "16"
      },
      {
        "id": "72f526f7-0539-386b-a4fc-a93d20d3eab6",
        "key": "D",
        "text": "32"
      }
    ],
    "correct_option_id": "bf78b14f-93d9-35ff-8e35-563a282d3de4",
    "explanation": "The correct answer is 16. Rearranging the equation into standard quadratic form:\n$$r^2 + (q - 2)r + 55 = 0$$\nA quadratic equation $ar^2 + br + c = 0$ has no real solutions if and only if its discriminant is strictly negative:\n$$b^2 - 4ac < 0 \\implies (q - 2)^2 - 4(1)(55) < 0$$\n$$(q - 2)^2 - 220 < 0 \\implies (q - 2)^2 < 220$$\n$$-\\sqrt{220} < q - 2 < \\sqrt{220}$$\n$$2 - \\sqrt{220} < q < 2 + \\sqrt{220}$$\nSince $\\sqrt{220} \\approx 14.83$:\n$$-12.83 < q < 16.83$$\nSince $q$ is an integer, the largest possible value of $q$ is 16.",
    "source_id": "46308566",
    "source_number": 19,
    "authored_distractors": true
  },
  {
    "id": "083cc1cc-6a44-5817-b63b-5f0645d5c57f",
    "external_key": "SAT_MATH:f65288e8",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_EQUATIONS",
    "topic_name": "Advanced Math / Nonlinear equations in one variable and systems of equations in two variables",
    "difficulty": "HARD",
    "prompt": "$$\\frac{1}{x^2 + 10x + 25} = 4$$\n\nIf $x$ is a solution to the given equation, which of the following is a possible value of $x + 5$?",
    "options": [
      {
        "id": "16549d40-2030-3949-a54b-ce688653a497",
        "key": "A",
        "text": "$\\frac{1}{2}$"
      },
      {
        "id": "b9347e24-b32b-3122-8873-31f2a4fc43a2",
        "key": "B",
        "text": "$\\frac{5}{2}$"
      },
      {
        "id": "85b7df75-9deb-3566-b0bb-3961ee5ec613",
        "key": "C",
        "text": "$\\frac{9}{2}$"
      },
      {
        "id": "b665ac12-639d-30d5-87f2-7ea985cf5748",
        "key": "D",
        "text": "$\\frac{11}{2}$"
      }
    ],
    "correct_option_id": "16549d40-2030-3949-a54b-ce688653a497",
    "explanation": "Choice A is correct. The denominator can be factored as $x^2 + 10x + 25 = (x + 5)^2$.\n$$\\frac{1}{(x + 5)^2} = 4 \\implies (x + 5)^2 = \\frac{1}{4}$$\nTaking the square root of both sides:\n$$x + 5 = \\pm \\frac{1}{2}$$\nTherefore, a possible value of $x + 5$ is $\\frac{1}{2}$.",
    "source_id": "f65288e8",
    "source_number": 20,
    "authored_distractors": false
  },
  {
    "id": "31c49468-add8-569b-8e0e-8971b2209f84",
    "external_key": "SAT_MATH:983412ea",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "HARD",
    "prompt": "A right square prism has a height of $14\\text{ units}$. The volume of the prism is $2{,}016\\text{ cubic units}$. What is the length, in units, of an edge of the base?",
    "options": [
      {
        "id": "5574f7d6-54f8-3939-a23c-e1dd6741b038",
        "key": "A",
        "text": "6"
      },
      {
        "id": "1b9af68f-de41-3e8d-ad70-67f271d0e494",
        "key": "B",
        "text": "18"
      },
      {
        "id": "11911f58-c4b4-3dcc-a084-cefe847b1af1",
        "key": "C",
        "text": "12"
      },
      {
        "id": "fd77e287-15a8-34a9-8a93-8e486739dfa4",
        "key": "D",
        "text": "24"
      }
    ],
    "correct_option_id": "11911f58-c4b4-3dcc-a084-cefe847b1af1",
    "explanation": "The correct answer is 12. The volume, $V$, of a right square prism can be calculated using the formula $V = s^2h$, where $s$ represents the length of an edge of the base and $h$ represents the height of the prism. It's given that the volume of the prism is $2{,}016\\text{ cubic units}$ and the height is $14\\text{ units}$. Substituting $2{,}016$ for $V$ and $14$ for $h$ in the formula yields:\n$$2{,}016 = (s^2)(14)$$\nDividing both sides of this equation by $14$ yields:\n$$144 = s^2$$\nTaking the square root of both sides of this equation yields two solutions: $-12 = s$ and $12 = s$. The length can't be negative, so $12 = s$. Therefore, the length, in units, of an edge of the base is 12.",
    "source_id": "983412ea",
    "source_number": 21,
    "authored_distractors": true
  },
  {
    "id": "23867d47-5f56-53ed-b899-37329f456f24",
    "external_key": "SAT_MATH:d12bca0a",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_CIRCLES",
    "topic_name": "Geometry and Trigonometry / Circles",
    "difficulty": "HARD",
    "prompt": "The circle shown has its center at $(0, 0)$ and passes through the points $(8, 0)$ and $(2, k)$, where $(2, k)$ lies in the first quadrant above the $x$-axis. What is the value of $k$?",
    "options": [
      {
        "id": "17368dbd-5950-336b-b773-71aab8ec2b9b",
        "key": "A",
        "text": "$6$"
      },
      {
        "id": "cc809ea6-7e81-34b6-af18-4835fddc904a",
        "key": "B",
        "text": "$7$"
      },
      {
        "id": "039f4868-c2c6-3306-9517-6e3187768ab7",
        "key": "C",
        "text": "$8$"
      },
      {
        "id": "881c27ed-3b82-30a7-abd1-e21c71548ddd",
        "key": "D",
        "text": "$\\sqrt{60}$"
      }
    ],
    "correct_option_id": "881c27ed-3b82-30a7-abd1-e21c71548ddd",
    "explanation": "Choice D is correct. The equation of a circle in the $xy$-plane with its center at $(0, 0)$ can be expressed as $x^2 + y^2 = r^2$, where $r$ is the radius of the circle. Since $(8, 0)$ lies on the circle, the radius of the circle is $r = 8$. Substituting $8$ for $r$ yields:\n$$x^2 + y^2 = 64$$\nIt is also given that $(2, k)$ lies on the circle. Substituting $2$ for $x$ and $k$ for $y$ yields:\n$$2^2 + k^2 = 64 \\implies 4 + k^2 = 64$$\nSubtracting $4$ from both sides yields:\n$$k^2 = 60$$\nTaking the square root of both sides yields $k = \\pm\\sqrt{60}$. Since $(2, k)$ lies above the $x$-axis, $k$ must be positive. Therefore:\n$$k = \\sqrt{60}$$",
    "source_id": "d12bca0a",
    "source_number": 22,
    "authored_distractors": false
  },
  {
    "id": "f1e118c8-4db4-5a27-9418-a866256461fd",
    "external_key": "SAT_MATH:a4c0547f",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "HARD",
    "prompt": "In triangle $XYZ$, angle $Z$ is a right angle and the length of $\\overline{YZ}$ is $24\\text{ units}$. If $\\tan X = \\frac{12}{35}$, what is the perimeter, in units, of triangle $XYZ$?",
    "options": [
      {
        "id": "a4237487-81dd-3545-b762-53206bb600f1",
        "key": "A",
        "text": "$188$"
      },
      {
        "id": "85aa4ff4-a020-33a3-861b-ec21a72c4682",
        "key": "B",
        "text": "$168$"
      },
      {
        "id": "6872d906-9e03-372f-9771-2ae690e62dc7",
        "key": "C",
        "text": "$84$"
      },
      {
        "id": "4b04bb60-9fdd-3224-8f9a-7a6e804a2272",
        "key": "D",
        "text": "$71$"
      }
    ],
    "correct_option_id": "85aa4ff4-a020-33a3-861b-ec21a72c4682",
    "explanation": "Choice B is correct. In right triangle $XYZ$, angle $Z$ is a right angle. Side $\\overline{YZ}$ is the leg opposite angle $X$, and side $\\overline{XZ}$ is the leg adjacent to angle $X$. Therefore:\n$$\\tan X = \\frac{YZ}{XZ}$$\nSubstituting $\\frac{12}{35}$ for $\\tan X$ and $24$ for $YZ$:\n$$\\frac{12}{35} = \\frac{24}{XZ} \\implies 12(XZ) = 35(24) = 840 \\implies XZ = 70$$\nUsing the Pythagorean theorem:\n$$XY^2 = XZ^2 + YZ^2 = 70^2 + 24^2 = 4{,}900 + 576 = 5{,}476$$\nTaking the square root:\n$$XY = \\sqrt{5{,}476} = 74$$\nThe perimeter of triangle $XYZ$ is the sum of the side lengths:\n$$\\text{Perimeter} = YZ + XZ + XY = 24 + 70 + 74 = 168$$",
    "source_id": "a4c0547f",
    "source_number": 23,
    "authored_distractors": false
  },
  {
    "id": "a905d366-a31e-5c37-b702-344649987664",
    "external_key": "SAT_MATH:947a3cde",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "HARD",
    "prompt": "In the figure, $\\overline{MQ}$ and $\\overline{NR}$ intersect at point $P$, $NP = QP$, and $MP = PR$. In triangle $NPQ$, the measure of angle $NQP$ is $70^\\circ$ and the measure of angle $MPN$ is $60^\\circ$. What is the measure, in degrees, of $\\angle QMR$? (Disregard the degree symbol when gridding your answer.)",
    "options": [
      {
        "id": "f8b18d20-dd3f-3bfc-a5ee-f262395a08af",
        "key": "A",
        "text": "15"
      },
      {
        "id": "40d6c6c7-4a5d-3254-a20f-0469e3091d4b",
        "key": "B",
        "text": "45"
      },
      {
        "id": "0d56b97f-8b89-363d-8e79-256eb57ec8f9",
        "key": "C",
        "text": "30"
      },
      {
        "id": "49147f1a-11b6-3c9b-8c74-a39b05f72188",
        "key": "D",
        "text": "60"
      }
    ],
    "correct_option_id": "0d56b97f-8b89-363d-8e79-256eb57ec8f9",
    "explanation": "The correct answer is 30. Angles $\\angle MPN$ and $\\angle QPR$ are vertical angles, so their measures are equal:\n$$m\\angle QPR = m\\angle MPN = 60^\\circ$$\nAngles $\\angle MPR$ and $\\angle QPR$ form a linear pair and are supplementary:\n$$m\\angle MPR + m\\angle QPR = 180^\\circ \\implies m\\angle MPR = 180^\\circ - 60^\\circ = 120^\\circ$$\nIn triangle $MPR$, it is given that $MP = PR$, so triangle $MPR$ is an isosceles triangle with base angles $\\angle PMR$ and $\\angle PRM$:\n$$m\\angle PMR = m\\angle PRM = \\frac{180^\\circ - 120^\\circ}{2} = \\frac{60^\\circ}{2} = 30^\\circ$$\nSince point $P$ lies on segment $\\overline{MQ}$, $\\angle QMR$ is the same angle as $\\angle PMR$. Therefore, the measure of $\\angle QMR$ is $30^\\circ$.",
    "source_id": "947a3cde",
    "source_number": 24,
    "authored_distractors": true
  },
  {
    "id": "c768b692-f901-5bd2-b536-aff45b1756f7",
    "external_key": "SAT_MATH:deff8a2f",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "HARD",
    "prompt": "The circumference of the base of a right circular cylinder is $20\\pi\\text{ meters}$, and the height of the cylinder is $6\\text{ meters}$. What is the volume, in cubic meters, of the cylinder?",
    "options": [
      {
        "id": "35f42aa7-9253-3d9f-aea5-c6ae0636597b",
        "key": "A",
        "text": "$60\\pi$"
      },
      {
        "id": "689e7dff-c497-3802-bca9-003d252d491c",
        "key": "B",
        "text": "$120\\pi$"
      },
      {
        "id": "8c471178-455e-364e-8d9f-990000148c37",
        "key": "C",
        "text": "$600\\pi$"
      },
      {
        "id": "9efcb1a9-73f9-36d8-9245-a5bc64f29d85",
        "key": "D",
        "text": "$2{,}400\\pi$"
      }
    ],
    "correct_option_id": "8c471178-455e-364e-8d9f-990000148c37",
    "explanation": "Choice C is correct. The volume $V$ of a right circular cylinder is given by the formula $V = \\pi r^2 h$, where $r$ is the radius of the base and $h$ is the height. The circumference of the circular base is given by:\n$$C = 2\\pi r = 20\\pi \\implies r = 10$$\nSubstituting $r = 10$ and $h = 6$ into the volume formula yields:\n$$V = \\pi(10)^2(6) = 600\\pi$$",
    "source_id": "deff8a2f",
    "source_number": 25,
    "authored_distractors": false
  },
  {
    "id": "4f6cca19-ab40-50a2-bbe0-2753001b5bd1",
    "external_key": "SAT_MATH:1fe41c6b",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "HARD",
    "prompt": "The table gives the areas and perimeters of two similar rectangles, where $n$ is a constant.\n\n| | Area (square inches) | Perimeter (inches) |\n| :--- | :---: | :---: |\n| **Rectangle A** | 630 | 210 |\n| **Rectangle B** | 2,520 | $n$ |\n\nWhat is the value of $n$?",
    "options": [
      {
        "id": "8f55dfad-b02f-36ee-bfe2-f4c5ad9ee626",
        "key": "A",
        "text": "$2{,}100$"
      },
      {
        "id": "0d5306f1-e5ec-38b6-b81a-7377898a99b1",
        "key": "B",
        "text": "$1{,}680$"
      },
      {
        "id": "6d669683-fc26-3370-b8b1-1e6c25b09994",
        "key": "C",
        "text": "$840$"
      },
      {
        "id": "bfba970f-b54c-3bf5-bd26-7d5cbbad36c2",
        "key": "D",
        "text": "$420$"
      }
    ],
    "correct_option_id": "bfba970f-b54c-3bf5-bd26-7d5cbbad36c2",
    "explanation": "Choice D is correct. Since rectangle A and rectangle B are similar, the ratio of their areas is equal to the square of the ratio of their linear dimensions (scale factor $k$):\n$$k^2 = \\frac{\\text{Area of B}}{\\text{Area of A}} = \\frac{2{,}520}{630} = 4$$\nTaking the positive square root:\n$$k = \\sqrt{4} = 2$$\nThe ratio of their perimeters equals the scale factor $k$:\n$$\\frac{\\text{Perimeter of B}}{\\text{Perimeter of A}} = k = 2 \\implies \\frac{n}{210} = 2 \\implies n = 2(210) = 420$$",
    "source_id": "1fe41c6b",
    "source_number": 26,
    "authored_distractors": false
  },
  {
    "id": "1fd45704-a9fc-5411-acf9-456aec33caeb",
    "external_key": "SAT_MATH:27d075d8",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "HARD",
    "prompt": "For two acute angles, $\\angle Q$ and $\\angle R$, $\\cos(Q) = \\sin(R)$. The measures, in degrees, of $\\angle Q$ and $\\angle R$ are $x + 52$ and $4x + 13$, respectively. What is the value of $x$?",
    "options": [
      {
        "id": "a1ccb347-1b33-3b75-8529-04346e823fb5",
        "key": "A",
        "text": "$5$"
      },
      {
        "id": "57bd7670-a2c0-3d35-b1c4-5d0e6d46c8bb",
        "key": "B",
        "text": "$13$"
      },
      {
        "id": "cf6468ba-c888-303b-886e-0aa0a1ae4f9d",
        "key": "C",
        "text": "$23$"
      },
      {
        "id": "acd490fd-6886-3fd4-866c-d4e040708fc7",
        "key": "D",
        "text": "$38$"
      }
    ],
    "correct_option_id": "a1ccb347-1b33-3b75-8529-04346e823fb5",
    "explanation": "Choice A is correct. For two acute angles, if the sine of one angle is equal to the cosine of the other, the angles are complementary, meaning their sum is $90^\\circ$:\n$$m\\angle Q + m\\angle R = 90^\\circ$$\n$$(x + 52) + (4x + 13) = 90$$\n$$5x + 65 = 90$$\n$$5x = 25 \\implies x = 5$$",
    "source_id": "27d075d8",
    "source_number": 27,
    "authored_distractors": false
  },
  {
    "id": "c683c50a-ce22-5170-a3c6-c275140e87e7",
    "external_key": "SAT_MATH:858fd1cf",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_CIRCLES",
    "topic_name": "Geometry and Trigonometry / Circles",
    "difficulty": "HARD",
    "prompt": "A circle in the $xy$-plane has its center at $(-1, 1)$. Line $t$ is tangent to this circle at the point $(5, -4)$. Which of the following points also lies on line $t$?",
    "options": [
      {
        "id": "96414aec-ab5e-326a-b9fe-1ca6a740e1a8",
        "key": "A",
        "text": "$(0, \\frac{6}{5})$"
      },
      {
        "id": "4238da28-c9b1-3eeb-bc3e-6ba2f4fe22aa",
        "key": "B",
        "text": "$(4, 7)$"
      },
      {
        "id": "2bb38d7c-17b6-3c53-8424-883ffb2e2d02",
        "key": "C",
        "text": "$(10, 2)$"
      },
      {
        "id": "6753dbd5-b963-3336-8c4f-2cb0a1e3fba6",
        "key": "D",
        "text": "$(11, 1)$"
      }
    ],
    "correct_option_id": "2bb38d7c-17b6-3c53-8424-883ffb2e2d02",
    "explanation": "Choice C is correct. The radius connecting the center $(-1, 1)$ and the point of tangency $(5, -4)$ has slope:\n$$m_{\\text{radius}} = \\frac{-4 - 1}{5 - (-1)} = \\frac{-5}{6} = -\\frac{5}{6}$$\nSince a tangent line is perpendicular to the radius at the point of tangency, the slope of line $t$ is the negative reciprocal:\n$$m_t = -\\frac{1}{-\\frac{5}{6}} = \\frac{6}{5}$$\nA point $(x, y)$ lies on line $t$ if the slope between $(x, y)$ and $(5, -4)$ is $\\frac{6}{5}$. Testing choice C, $(10, 2)$:\n$$\\frac{2 - (-4)}{10 - 5} = \\frac{6}{5}$$\nSince the slope equals $\\frac{6}{5}$, the point $(10, 2)$ lies on line $t$.",
    "source_id": "858fd1cf",
    "source_number": 28,
    "authored_distractors": false
  },
  {
    "id": "e4472b6b-5392-50a9-a4de-79c9876ebbb6",
    "external_key": "SAT_MATH:9adb86ed",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_CIRCLES",
    "topic_name": "Geometry and Trigonometry / Circles",
    "difficulty": "HARD",
    "prompt": "Points $Q$ and $R$ lie on a circle with center $P$. The radius of this circle is $9\\text{ inches}$. Triangle $PQR$ has a perimeter of $31\\text{ inches}$. What is the length, in inches, of $\\overline{QR}$?",
    "options": [
      {
        "id": "a1b37439-a9f6-3b25-8d5f-abc52ebc535a",
        "key": "A",
        "text": "$13\\sqrt{2}$"
      },
      {
        "id": "52791169-5712-3775-a389-70f54aa0097f",
        "key": "B",
        "text": "$13$"
      },
      {
        "id": "c8a7b091-820c-37e0-9ebe-eae482ebb5f2",
        "key": "C",
        "text": "$9\\sqrt{2}$"
      },
      {
        "id": "2b1e3f9a-2418-31f7-9de6-23086a558f01",
        "key": "D",
        "text": "$9$"
      }
    ],
    "correct_option_id": "52791169-5712-3775-a389-70f54aa0097f",
    "explanation": "Choice B is correct. Since $P$ is the center of the circle and $Q$ and $R$ lie on the circle, segments $\\overline{PQ}$ and $\\overline{PR}$ are radii, so $PQ = 9$ and $PR = 9$. The perimeter of triangle $PQR$ is:\n$$\\text{Perimeter} = PQ + PR + QR = 9 + 9 + QR = 18 + QR$$\nGiven that the perimeter is $31\\text{ inches}$:\n$$18 + QR = 31 \\implies QR = 13$$",
    "source_id": "9adb86ed",
    "source_number": 29,
    "authored_distractors": false
  },
  {
    "id": "f531c844-f9af-540b-a3da-ede0c0cfefb8",
    "external_key": "SAT_MATH:1dc7e423",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "HARD",
    "prompt": "In triangle $ABC$, the measure of angle $A$ is $52^\\circ$ and $AC = 30$. In triangle $PQR$, the measure of angle $P$ is $52^\\circ$ and $PR = 120$. Which additional piece of information is sufficient to prove that triangle $ABC$ is similar to triangle $PQR$?",
    "options": [
      {
        "id": "55da89e5-92e2-32f5-ad07-a86629722c2b",
        "key": "A",
        "text": "$AB = 50$ and $PQ = 50$."
      },
      {
        "id": "88823499-798d-3d1d-94ff-2c5951c3fcb9",
        "key": "B",
        "text": "$AB = 50$ and $QR = 200$."
      },
      {
        "id": "2a81ba02-ce74-355e-9598-9552f236c5ae",
        "key": "C",
        "text": "The measures of angle $B$ and angle $R$ are $32^\\circ$ and $96^\\circ$, respectively."
      },
      {
        "id": "e9c6d498-cfb0-3fd9-a00c-bb1e01e3baf6",
        "key": "D",
        "text": "The measures of angle $B$ and angle $Q$ are $52^\\circ$ and $32^\\circ$, respectively."
      }
    ],
    "correct_option_id": "2a81ba02-ce74-355e-9598-9552f236c5ae",
    "explanation": "Choice C is correct. Triangle similarity by the Angle-Angle (AA) criterion requires two pairs of congruent corresponding angles. In triangle $ABC$, if $\\angle A = 52^\\circ$ and $\\angle B = 32^\\circ$, then:\n$$m\\angle C = 180^\\circ - (52^\\circ + 32^\\circ) = 96^\\circ$$\nIn triangle $PQR$, if $\\angle P = 52^\\circ$ and $\\angle R = 96^\\circ$, then:\n$$m\\angle Q = 180^\\circ - (52^\\circ + 96^\\circ) = 32^\\circ$$\nThus, $\\angle A \\cong \\angle P = 52^\\circ$, $\\angle B \\cong \\angle Q = 32^\\circ$, and $\\angle C \\cong \\angle R = 96^\\circ$. All corresponding angles are equal, which proves that $\\triangle ABC \\sim \\triangle PQR$.",
    "source_id": "1dc7e423",
    "source_number": 30,
    "authored_distractors": false
  },
  {
    "id": "bfb9f764-69e5-50e2-be66-7a8ffc4200fd",
    "external_key": "SAT_MATH:993000da",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PERCENTAGES",
    "topic_name": "Problem-Solving and Data Analysis / Percentages",
    "difficulty": "HARD",
    "prompt": "The positive number $a$ is $230\\%$ of the number $b$, and $a$ is $60\\%$ of the number $c$. If $c$ is $p\\%$ of $b$, which of the following is closest to the value of $p$?",
    "options": [
      {
        "id": "ac77274f-cc4d-32b7-ba1f-8381f5853875",
        "key": "A",
        "text": "$138$"
      },
      {
        "id": "11c40d99-4c36-3269-80a0-b552d6ccd699",
        "key": "B",
        "text": "$217$"
      },
      {
        "id": "976f8649-09a9-39b8-939e-0ca300364df4",
        "key": "C",
        "text": "$283$"
      },
      {
        "id": "ffaa09db-ada7-3a3c-9194-bb17b4eeb3a3",
        "key": "D",
        "text": "$383$"
      }
    ],
    "correct_option_id": "ffaa09db-ada7-3a3c-9194-bb17b4eeb3a3",
    "explanation": "Choice D is correct. Expressing the relationships algebraically:\n$$a = \\frac{230}{100}b = 2.3b$$\n$$a = \\frac{60}{100}c = 0.6c$$\nSetting the two expressions for $a$ equal to each other:\n$$0.6c = 2.3b \\implies c = \\frac{2.3}{0.6}b = \\frac{23}{6}b$$\nSince $c$ is $p\\%$ of $b$:\n$$c = \\frac{p}{100}b \\implies \\frac{p}{100} = \\frac{23}{6} \\implies p = \\frac{2{,}300}{6} \\approx 383.33$$\nTherefore, $383$ is closest to the value of $p$.",
    "source_id": "993000da",
    "source_number": 31,
    "authored_distractors": false
  },
  {
    "id": "ba6d9769-f80d-51c2-ac96-15931abdcc27",
    "external_key": "SAT_MATH:f6c18a66",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "HARD",
    "prompt": "For data set A, the table summarizes the distribution of the number of deliveries received by an office each day during a period of $11\\text{ days}$.\n\n| Deliveries | Days |\n| :---: | :---: |\n| 0 | 2 |\n| 3 | 2 |\n| 4 | 2 |\n| 5 | 2 |\n| 6 | 1 |\n| 7 | 1 |\n| 13 | 1 |\n\nThe data value $13$ was recorded in error and is removed from data set A to create data set B, which consists of the remaining $10\\text{ data values}$. Which statement best compares the median of data set A and the median of data set B?",
    "options": [
      {
        "id": "d01c691d-c8a0-323c-85c1-913fb6d15055",
        "key": "A",
        "text": "The median of data set B is less than the median of data set A."
      },
      {
        "id": "64c1b579-7f90-3c24-b784-a5f1f7077c1c",
        "key": "B",
        "text": "The median of data set B is greater than the median of data set A."
      },
      {
        "id": "53cac692-493a-3db3-9a4c-5d25c970c8b5",
        "key": "C",
        "text": "The median of data set B is equal to the median of data set A."
      },
      {
        "id": "327bb6e4-6be6-3896-8e74-4f3fa17abee2",
        "key": "D",
        "text": "There is not enough information to compare the medians of the two data sets."
      }
    ],
    "correct_option_id": "53cac692-493a-3db3-9a4c-5d25c970c8b5",
    "explanation": "Choice C is correct. In data set A ($11$ values in ascending order):\n$$0, 0, 3, 3, 4, 4, 5, 5, 6, 7, 13$$\nThe median is the 6th value, which is $4$.\nWhen $13$ is removed, data set B contains $10$ values:\n$$0, 0, 3, 3, 4, 4, 5, 5, 6, 7$$\nThe median is the average of the 5th and 6th values:\n$$\\frac{4 + 4}{2} = 4$$\nTherefore, the median of data set B is equal to the median of data set A.",
    "source_id": "f6c18a66",
    "source_number": 32,
    "authored_distractors": false
  },
  {
    "id": "7399035e-c853-5dfd-a3ed-614d4f0700cc",
    "external_key": "SAT_MATH:190be2fc",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "HARD",
    "prompt": "Data set A consists of $10\\text{ positive integers}$ less than $60$. The list shown gives $9$ of the integers from data set A:\n$$43, 45, 44, 43, 38, 39, 40, 46, 40$$\nThe mean of these $9\\text{ integers}$ is $42$. If the mean of data set A is an integer that is greater than $42$, what is the value of the largest integer from data set A?",
    "options": [
      {
        "id": "411f5286-b61c-39be-a94c-64e14834cb9e",
        "key": "A",
        "text": "52"
      },
      {
        "id": "de6e4a1d-0a80-32a9-8477-a87d606439b7",
        "key": "B",
        "text": "13"
      },
      {
        "id": "4cf66413-0ec9-3c77-a593-fb540eca056b",
        "key": "C",
        "text": "26"
      },
      {
        "id": "3c8a5362-87b7-3fc0-85fa-27cf3587bbf0",
        "key": "D",
        "text": "104"
      }
    ],
    "correct_option_id": "411f5286-b61c-39be-a94c-64e14834cb9e",
    "explanation": "The correct answer is 52. The sum of the given 9 integers is:\n$$43 + 45 + 44 + 43 + 38 + 39 + 40 + 46 + 40 = 378$$\nLet $x$ be the 10th integer in data set A. The mean of all 10 integers is:\n$$\\text{Mean} = \\frac{378 + x}{10}$$\nSince the mean is an integer, $378 + x$ must be a multiple of $10$, which means $x$ must have a ones digit of $2$.\nIt is also given that the mean is greater than $42$:\n$$\\frac{378 + x}{10} > 42 \\implies 378 + x > 420 \\implies x > 42$$\nSince all integers are less than $60$:\n$$42 < x < 60$$\nThe only integer between $42$ and $60$ with a ones digit of $2$ is $x = 52$. Because $52$ is greater than each of the 9 integers shown (the largest of which is $46$), $52$ is the largest integer in data set A.",
    "source_id": "190be2fc",
    "source_number": 33,
    "authored_distractors": true
  },
  {
    "id": "fe478db3-9076-5849-9f3f-ed8528a788f5",
    "external_key": "SAT_MATH:db88a933",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "HARD",
    "prompt": "**Data Set Q**\n\n| Value | Frequency |\n| :---: | :---: |\n| $a$ | 110 |\n| $b$ | 30 |\n| $c$ | 0 |\n\n**Data Set R**\n\n| Value | Frequency |\n| :---: | :---: |\n| $a$ | 0 |\n| $b$ | 3 |\n| $c$ | 11 |\n\nData sets Q and R are summarized in the tables shown, where $a$, $b$, and $c$ are positive, consecutive integers and $a < b < c$. Which statement comparing the means of the data sets is true?",
    "options": [
      {
        "id": "e610ab9d-565e-3085-93ee-a21e57e13a24",
        "key": "A",
        "text": "The mean of data set R is $\\frac{2(11)}{14}$ less than the mean of data set Q."
      },
      {
        "id": "1678fa96-4479-397e-a29a-a2f941077ac3",
        "key": "B",
        "text": "The mean of data set R is $\\frac{2(11)}{14}$ greater than the mean of data set Q."
      },
      {
        "id": "b7a7983b-3555-3443-9633-dea26d0c2c88",
        "key": "C",
        "text": "The mean of data set Q is $10$ times the mean of data set R."
      },
      {
        "id": "bec0e326-03fc-3ca2-bb28-5b3785fe42ff",
        "key": "D",
        "text": "The means of the two data sets are equal."
      }
    ],
    "correct_option_id": "1678fa96-4479-397e-a29a-a2f941077ac3",
    "explanation": "Choice B is correct. Since $a, b, c$ are consecutive integers with $a < b < c$, we have $b = a + 1$ and $c = a + 2$.\nFor data set Q, the total number of values is $110 + 30 + 0 = 140$:\n$$\\text{Mean}_Q = \\frac{110a + 30(a + 1)}{140} = \\frac{140a + 30}{140} = a + \\frac{30}{140} = a + \\frac{3}{14}$$\nFor data set R, the total number of values is $0 + 3 + 11 = 14$:\n$$\\text{Mean}_R = \\frac{3(a + 1) + 11(a + 2)}{14} = \\frac{14a + 3 + 22}{14} = a + \\frac{3 + 2(11)}{14} = a + \\frac{3}{14} + \\frac{2(11)}{14}$$\nSubtracting $\\text{Mean}_Q$ from $\\text{Mean}_R$:\n$$\\text{Mean}_R - \\text{Mean}_Q = \\left(a + \\frac{3}{14} + \\frac{2(11)}{14}\\right) - \\left(a + \\frac{3}{14}\\right) = \\frac{2(11)}{14}$$\nTherefore, the mean of data set R is $\\frac{2(11)}{14}$ greater than the mean of data set Q.",
    "source_id": "db88a933",
    "source_number": 34,
    "authored_distractors": false
  },
  {
    "id": "573f2988-8420-53b9-bf83-d28aed1e0ff3",
    "external_key": "SAT_MATH:2e8027b0",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_TWO_VARIABLES",
    "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
    "difficulty": "HARD",
    "prompt": "The scatterplot shows the relationship between two variables, $x$ and $y$, for data set E. A line of best fit is shown. Data set F is created by multiplying the $y$-coordinate of each data point from data set E by $3.9$. Which of the following could be an equation of a line of best fit for data set F?",
    "options": [
      {
        "id": "0ec1e232-2bcf-3036-bae0-51563e3f5f4b",
        "key": "A",
        "text": "$y = 46.8 + 5.9x$"
      },
      {
        "id": "0e287ccd-0a27-30a0-a67a-022a03cbbae4",
        "key": "B",
        "text": "$y = 46.8 + 1.5x$"
      },
      {
        "id": "13b491ad-59ca-3bfc-a6cd-c2dd48665c9f",
        "key": "C",
        "text": "$y = 12 + 5.9x$"
      },
      {
        "id": "992cd468-d60a-35f4-b284-cb9578f58b8c",
        "key": "D",
        "text": "$y = 12 + 1.5x$"
      }
    ],
    "correct_option_id": "0ec1e232-2bcf-3036-bae0-51563e3f5f4b",
    "explanation": "Choice A is correct. The line of best fit for data set E has a $y$-intercept at approximately $(0, 12)$ and passes through approximately $(12, 30)$. Its slope is:\n$$m_E \\approx \\frac{30 - 12}{12 - 0} = \\frac{18}{12} = 1.5$$\nThus the line of best fit for data set E is approximately $y = 12 + 1.5x$.\nSince each $y$-coordinate is multiplied by $3.9$ to create data set F, both the $y$-intercept and slope are scaled by $3.9$:\n$$\\text{New } y\\text{-intercept} = 12 \\times 3.9 = 46.8$$\n$$\\text{New slope} = 1.5 \\times 3.9 = 5.85 \\approx 5.9$$\nTherefore, an equation of a line of best fit for data set F is $y = 46.8 + 5.9x$.",
    "source_id": "2e8027b0",
    "source_number": 35,
    "authored_distractors": false
  },
  {
    "id": "636ac7ff-2e9a-5b69-a698-1082f0f9bd7f",
    "external_key": "SAT_MATH:c178d4da",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "HARD",
    "prompt": "| Value | Data set A frequency | Data set B frequency |\n| :---: | :---: | :---: |\n| 30 | 2 | 9 |\n| 34 | 4 | 7 |\n| 38 | 5 | 5 |\n| 42 | 7 | 4 |\n| 46 | 9 | 2 |\n\nData set A and data set B each consist of $27\\text{ values}$. The table shows the frequencies of the values for each data set. Which of the following statements best compares the means of the two data sets?",
    "options": [
      {
        "id": "a7bbbb8a-64f2-3baf-86d6-4f03e63c03b0",
        "key": "A",
        "text": "The mean of data set A is greater than the mean of data set B."
      },
      {
        "id": "6cb00cc4-8beb-35a7-812b-939770ead7a5",
        "key": "B",
        "text": "The mean of data set A is less than the mean of data set B."
      },
      {
        "id": "b7195f1d-23b8-30b2-be82-cefd0fbb591e",
        "key": "C",
        "text": "The mean of data set A is equal to the mean of data set B."
      },
      {
        "id": "e3d2f8f2-6c4a-30db-907d-2502ab897cda",
        "key": "D",
        "text": "There is not enough information to compare the means of the data sets."
      }
    ],
    "correct_option_id": "a7bbbb8a-64f2-3baf-86d6-4f03e63c03b0",
    "explanation": "Choice A is correct. The sum of the values in data set A is:\n$$30(2) + 34(4) + 38(5) + 42(7) + 46(9) = 60 + 136 + 190 + 294 + 414 = 1{,}094$$\n$$\\text{Mean}_A = \\frac{1{,}094}{27} \\approx 40.52$$\nThe sum of the values in data set B is:\n$$30(9) + 34(7) + 38(5) + 42(4) + 46(2) = 270 + 238 + 190 + 168 + 92 = 958$$\n$$\\text{Mean}_B = \\frac{958}{27} \\approx 35.48$$\nTherefore, the mean of data set A is greater than the mean of data set B.",
    "source_id": "c178d4da",
    "source_number": 36,
    "authored_distractors": false
  },
  {
    "id": "5efab0da-7ff2-5f5d-b79b-bc578967ecf7",
    "external_key": "SAT_MATH:457d2f2c",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "HARD",
    "prompt": "A data set of $27\\text{ different numbers}$ has a mean of $33$ and a median of $33$. A new data set is created by adding $7$ to each number in the original data set that is greater than the median and subtracting $7$ from each number in the original data set that is less than the median. Which of the following measures does NOT have the same value in both the original and new data sets?",
    "options": [
      {
        "id": "b63a3de7-a0fc-3e29-b515-b8d4bbf6b415",
        "key": "A",
        "text": "Median"
      },
      {
        "id": "f69dfe7f-71eb-38cd-b643-fb5acdd6b39e",
        "key": "B",
        "text": "Mean"
      },
      {
        "id": "332cf855-3f8f-39c0-802c-9a4334e4f538",
        "key": "C",
        "text": "Sum of the numbers"
      },
      {
        "id": "cf38cb15-f110-361a-9105-e8b8d21322ab",
        "key": "D",
        "text": "Standard deviation"
      }
    ],
    "correct_option_id": "cf38cb15-f110-361a-9105-e8b8d21322ab",
    "explanation": "Choice D is correct. In a data set of 27 distinct numbers, 13 numbers are strictly less than the median (33), one number is the median (33), and 13 numbers are strictly greater than the median (33).\n- Adding 7 to the 13 numbers above 33 and subtracting 7 from the 13 numbers below 33 produces a net change of $13(+7) + 13(-7) = 0$. Therefore, both the **sum of the numbers** and the **mean** remain unchanged.\n- The middle value remains 33, so the **median** does not change.\n- However, the values greater than the mean are shifted farther away to the right, and the values less than the mean are shifted farther away to the left. This increases the dispersion (spread) of the data from the mean, which directly increases the **standard deviation**. Therefore, the standard deviation does NOT have the same value.",
    "source_id": "457d2f2c",
    "source_number": 37,
    "authored_distractors": false
  },
  {
    "id": "21d18ba4-3d8d-5036-91e1-6a2b3c73897d",
    "external_key": "SAT_MATH:e438ec3f",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PROBABILITY",
    "topic_name": "Problem-Solving and Data Analysis / Probability and conditional probability",
    "difficulty": "HARD",
    "prompt": "A grove has $6\\text{ rows}$ of birch trees and $5\\text{ rows}$ of maple trees. Each row of birch trees has $8\\text{ trees } 20\\text{ feet or taller}$ and $6\\text{ trees shorter than } 20\\text{ feet}$. Each row of maple trees has $9\\text{ trees } 20\\text{ feet or taller}$ and $7\\text{ trees shorter than } 20\\text{ feet}$. A tree from one of these rows will be selected at random. What is the probability of selecting a maple tree, given that the tree is $20\\text{ feet or taller}$?",
    "options": [
      {
        "id": "23665036-705f-32d8-abfa-196092481084",
        "key": "A",
        "text": "$\\frac{9}{164}$"
      },
      {
        "id": "2bf4c01b-7c6d-32e2-924e-28fd55808ed0",
        "key": "B",
        "text": "$\\frac{3}{10}$"
      },
      {
        "id": "be2f9de8-a509-3e68-8b71-4cbb42c63305",
        "key": "C",
        "text": "$\\frac{15}{31}$"
      },
      {
        "id": "617936c6-aada-35c8-92f7-7f478b44de74",
        "key": "D",
        "text": "$\\frac{9}{17}$"
      }
    ],
    "correct_option_id": "be2f9de8-a509-3e68-8b71-4cbb42c63305",
    "explanation": "Choice C is correct. The conditional probability is the number of maple trees $20\\text{ feet or taller}$ divided by the total number of trees $20\\text{ feet or taller}$.\n- Maple trees $20\\text{ ft or taller}$: $5 \\text{ rows} \\times 9 = 45$ trees.\n- Birch trees $20\\text{ ft or taller}$: $6 \\text{ rows} \\times 8 = 48$ trees.\n- Total trees $20\\text{ ft or taller}$: $45 + 48 = 93$ trees.\nThe probability is:\n$$P(\\text{maple} \\mid \\ge 20\\text{ ft}) = \\frac{45}{93} = \\frac{15}{31}$$",
    "source_id": "e438ec3f",
    "source_number": 38,
    "authored_distractors": false
  },
  {
    "id": "c84ccd61-6d0c-5443-ad00-dbf31d9b6ce4",
    "external_key": "SAT_MATH:d6af3572",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_TWO_VARIABLES",
    "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
    "difficulty": "HARD",
    "prompt": "The scatterplot shows the federal-mandated minimum wage every 10 years between 1940 and 2010. A line of best fit is shown, and its equation is $y = 0.096x - 0.488$, where $x$ represents the number of years since 1940 and $y$ represents the minimum wage in dollars per hour. What does the line of best fit predict about the increase in the minimum wage over the 70-year period?",
    "options": [
      {
        "id": "d0c69a01-42b2-39b2-9189-01d4a5e96fea",
        "key": "A",
        "text": "Each year between 1940 and 2010, the average increase in minimum wage was 0.096 dollars."
      },
      {
        "id": "25339732-28c6-3d75-ab17-6f2840fafbdf",
        "key": "B",
        "text": "Each year between 1940 and 2010, the average increase in minimum wage was 0.49 dollars."
      },
      {
        "id": "6dc4df5c-a61f-3294-81b5-cd0cd22f48bb",
        "key": "C",
        "text": "Every 10 years between 1940 and 2010, the average increase in minimum wage was 0.096 dollars."
      },
      {
        "id": "4b9d1b76-d6a7-3194-b7a7-b14f4fcc8d83",
        "key": "D",
        "text": "Every 10 years between 1940 and 2010, the average increase in minimum wage was 0.488 dollars."
      }
    ],
    "correct_option_id": "d0c69a01-42b2-39b2-9189-01d4a5e96fea",
    "explanation": "Choice A is correct. The equation of the line of best fit is given in slope-intercept form, $y = mx + b$, where $m$ is the slope. Here, $m = 0.096$. By definition, the slope represents the change in $y$ for each 1-unit increase in $x$. Since $x$ is measured in single years and $y$ is measured in dollars per hour, the line of best fit predicts that each year between 1940 and 2010, the average increase in the minimum wage was 0.096 dollars per hour.",
    "source_id": "d6af3572",
    "source_number": 39,
    "authored_distractors": false
  },
  {
    "id": "336782d2-4552-5736-acc3-b529c924b1c3",
    "external_key": "SAT_MATH:89ff6a0a",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PROBABILITY",
    "topic_name": "Problem-Solving and Data Analysis / Probability and conditional probability",
    "difficulty": "HARD",
    "prompt": "For $100\\text{ buttons}$, the table summarizes the distribution by group and diameter.\n\n| Group | Less than 20 mm | 20 to 30 mm | Greater than 30 mm |\n| :--- | :---: | :---: | :---: |\n| **Group 1** | 12 | 8 | 3 |\n| **Group 2** | 0 | 17 | 18 |\n| **Group 3** | 10 | 32 | 0 |\n\nOne of these buttons will be selected at random. What is the probability of selecting a button with a diameter that is less than or equal to $30\\text{ millimeters}$, given that it is not in group 2? (Express your answer as a decimal or fraction, not as a percent.)",
    "options": [
      {
        "id": "68860fc8-af72-34a5-b6b8-0c2224779098",
        "key": "A",
        "text": "0.0462"
      },
      {
        "id": "fc0c4469-f44c-37c0-a7da-c0b4fbc1cfc5",
        "key": "B",
        "text": "0.5"
      },
      {
        "id": "c6d0811b-006e-3761-91f5-00f6e802a1e6",
        "key": "C",
        "text": ".9538, 62/65"
      },
      {
        "id": "52265f53-c794-3d02-8273-32b554f9bde1",
        "key": "D",
        "text": "65/62"
      }
    ],
    "correct_option_id": "c6d0811b-006e-3761-91f5-00f6e802a1e6",
    "explanation": "The correct answer is $\\frac{62}{65}$ (or approximately $.9538$). The condition specifies that the selected button is not in Group 2, meaning it must be in Group 1 or Group 3.\n- Total buttons not in Group 2:\n  $$\\text{Group 1} = 12 + 8 + 3 = 23$$\n  $$\\text{Group 3} = 10 + 32 + 0 = 42$$\n  $$\\text{Total} = 23 + 42 = 65$$\n- Buttons not in Group 2 with diameter $\\le 30\\text{ mm}$:\n  $$\\text{Group 1} = 12 + 8 = 20$$\n  $$\\text{Group 3} = 10 + 32 = 42$$\n  $$\\text{Total} = 20 + 42 = 62$$\nThe conditional probability is therefore:\n$$\\frac{62}{65} \\approx 0.9538$$",
    "source_id": "89ff6a0a",
    "source_number": 40,
    "authored_distractors": true
  },
  {
    "id": "5d0b06df-a923-5036-8569-8c76671473c3",
    "external_key": "SAT_MATH:002dba45",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
    "topic_name": "Algebra / Linear equations in two variables",
    "difficulty": "MEDIUM",
    "prompt": "Line $k$ is defined by $y = -\\frac{17}{3}x + 5$. Line $j$ is perpendicular to line $k$ in the $xy$-plane. What is the slope of line $j$?",
    "options": [
      {
        "id": "2a349d93-1b38-3796-8d80-b8cc3df07ecf",
        "key": "A",
        "text": "0.8235"
      },
      {
        "id": "9c5791ec-3d1a-3a65-8d01-aa31f8ac4291",
        "key": "B",
        "text": ".1764, .1765, 3/17"
      },
      {
        "id": "a7920eb6-0706-3c49-89c7-3ec9480c19c1",
        "key": "C",
        "text": "1/17"
      },
      {
        "id": "d2927f8d-152b-32b8-99f5-b0a4174f35a1",
        "key": "D",
        "text": "17/3"
      }
    ],
    "correct_option_id": "9c5791ec-3d1a-3a65-8d01-aa31f8ac4291",
    "explanation": "The correct answer is $\\frac{3}{17}$ (or $.1764$, $.1765$). The equation of line $k$ is given in slope-intercept form $y = mx + b$, where $m = -\\frac{17}{3}$ is the slope. Since line $j$ is perpendicular to line $k$, its slope must be the negative reciprocal of $-\\frac{17}{3}$:\n$$m_j = -\\frac{1}{-\\frac{17}{3}} = \\frac{3}{17}$$\nIn decimal form, $\\frac{3}{17} \\approx 0.17647$, which can be entered as $3/17$, $.1764$, or $.1765$.",
    "source_id": "002dba45",
    "source_number": 41,
    "authored_distractors": true
  },
  {
    "id": "aa80cc74-246e-5e74-9493-68e1d85d1ae2",
    "external_key": "SAT_MATH:f224df07",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_INEQUALITIES",
    "topic_name": "Algebra / Linear inequalities in one or two variables",
    "difficulty": "MEDIUM",
    "prompt": "A cargo helicopter delivers only 100-pound packages and 120-pound packages. For each delivery trip, the helicopter must carry at least 10 packages, and the total weight of the packages can be at most 1,100 pounds. What is the maximum number of 120-pound packages that the helicopter can carry per trip?",
    "options": [
      {
        "id": "4a86173a-9a7d-3a73-93ae-5c9a0dfb32f3",
        "key": "A",
        "text": "2"
      },
      {
        "id": "72b9ab3d-961c-3255-a509-9b85f06be16d",
        "key": "B",
        "text": "4"
      },
      {
        "id": "d6834390-9fa2-3a8a-a4b7-05e96888975f",
        "key": "C",
        "text": "5"
      },
      {
        "id": "572e2048-0462-3dcd-968c-d2a3a006d81b",
        "key": "D",
        "text": "6"
      }
    ],
    "correct_option_id": "d6834390-9fa2-3a8a-a4b7-05e96888975f",
    "explanation": "Choice C is correct. Let $a$ represent the number of 120-pound packages and $b$ represent the number of 100-pound packages. The problem conditions can be represented by the system of inequalities:\n$$a + b \\ge 10$$\n$$120a + 100b \\le 1{,}100$$\nTo maximize $a$, we minimize $b$, so we set $b = 10 - a$:\n$$120a + 100(10 - a) \\le 1{,}100$$\n$$120a + 1{,}000 - 100a \\le 1{,}100$$\n$$20a \\le 100 \\implies a \\le 5$$\nTherefore, the maximum number of 120-pound packages the helicopter can carry per trip is 5.",
    "source_id": "f224df07",
    "source_number": 42,
    "authored_distractors": false
  },
  {
    "id": "4708c5a3-c945-5181-b25e-915e0ef3cc1d",
    "external_key": "SAT_MATH:1480dd5c",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "MEDIUM",
    "prompt": "For the linear function $f$, $b$ is a constant and $f(x) = 4x + b$. If $f(7) = 28$, what is the value of $b$?",
    "options": [
      {
        "id": "fadafb55-ccb1-30f4-a3d9-bd5d0864af0b",
        "key": "A",
        "text": "0"
      },
      {
        "id": "f6dc894d-7155-34cb-a3f0-b3809e534173",
        "key": "B",
        "text": "1"
      },
      {
        "id": "705d39b7-ca22-39a3-b761-20cf36a255db",
        "key": "C",
        "text": "4"
      },
      {
        "id": "6515814e-b100-3dcb-8ccb-5433f406f3f7",
        "key": "D",
        "text": "7"
      }
    ],
    "correct_option_id": "fadafb55-ccb1-30f4-a3d9-bd5d0864af0b",
    "explanation": "Choice A is correct. Given $f(x) = 4x + b$ and $f(7) = 28$:\n$$f(7) = 4(7) + b = 28 \\implies 28 + b = 28 \\implies b = 0$$",
    "source_id": "1480dd5c",
    "source_number": 43,
    "authored_distractors": false
  },
  {
    "id": "39f7d802-2489-574c-95cd-1df4dc4d9c5a",
    "external_key": "SAT_MATH:cb8f449f",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "MEDIUM",
    "prompt": "$$\\begin{cases} \\frac{1}{2}y = 4 \\\\ x - \\frac{1}{2}y = 2 \\end{cases}$$\n\nThe system of equations above has solution $(x, y)$. What is the value of $x$?",
    "options": [
      {
        "id": "82a75ebc-f6a7-322c-883d-5b58d49bbdd3",
        "key": "A",
        "text": "3"
      },
      {
        "id": "bde05667-0bf9-3d20-bb73-f70fef4132b9",
        "key": "B",
        "text": "$\\frac{7}{2}$"
      },
      {
        "id": "ef6de3b1-4cd7-3fd9-90b3-2a7185057799",
        "key": "C",
        "text": "4"
      },
      {
        "id": "7b01fc91-2f05-3a8b-a828-e77a95a5bc06",
        "key": "D",
        "text": "6"
      }
    ],
    "correct_option_id": "7b01fc91-2f05-3a8b-a828-e77a95a5bc06",
    "explanation": "Choice D is correct. Adding the corresponding sides of the two equations eliminates the $y$-terms:\n$$\\left(\\frac{1}{2}y\\right) + \\left(x - \\frac{1}{2}y\\right) = 4 + 2 \\implies x = 6$$",
    "source_id": "cb8f449f",
    "source_number": 44,
    "authored_distractors": false
  },
  {
    "id": "c93d38a3-a756-5be8-874b-951fadd3d0e8",
    "external_key": "SAT_MATH:548a4929",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "MEDIUM",
    "prompt": "The function $h$ is defined by $h(x) = 4x + 28$. The graph of $y = h(x)$ in the $xy$-plane has an $x$-intercept at $(a, 0)$ and a $y$-intercept at $(0, b)$, where $a$ and $b$ are constants. What is the value of $a + b$?",
    "options": [
      {
        "id": "8ac7d1b8-8b7b-306d-8793-6b5121703aaf",
        "key": "A",
        "text": "21"
      },
      {
        "id": "95ee8511-b25b-33a0-af5b-8ee29a01a9f4",
        "key": "B",
        "text": "28"
      },
      {
        "id": "e00e6eb2-a8eb-3232-9b3f-f5cb9e5cc284",
        "key": "C",
        "text": "32"
      },
      {
        "id": "c5ecae37-8a67-3b86-9c54-817408fd3ec7",
        "key": "D",
        "text": "35"
      }
    ],
    "correct_option_id": "8ac7d1b8-8b7b-306d-8793-6b5121703aaf",
    "explanation": "Choice A is correct. The $x$-intercept occurs where $y = 0$:\n$$0 = 4a + 28 \\implies 4a = -28 \\implies a = -7$$\nThe $y$-intercept occurs where $x = 0$:\n$$b = 4(0) + 28 = 28$$\nTherefore:\n$$a + b = -7 + 28 = 21$$",
    "source_id": "548a4929",
    "source_number": 45,
    "authored_distractors": false
  },
  {
    "id": "565e3f17-84b0-5ee4-8d0a-869129760d17",
    "external_key": "SAT_MATH:e62cfe5f",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "MEDIUM",
    "prompt": "According to a model, the head width, in millimeters, of a worker bumblebee can be estimated by adding 0.6 to four times the body weight of the bee, in grams. According to the model, what would be the head width, in millimeters, of a worker bumblebee that has a body weight of 0.5 grams?",
    "options": [
      {
        "id": "9f076a54-85fa-3525-981f-8997c4c8dcc6",
        "key": "A",
        "text": "1.3"
      },
      {
        "id": "e06fec42-901f-357b-b362-96c288c4696f",
        "key": "B",
        "text": "3.6"
      },
      {
        "id": "d5a18e65-f06c-3159-8cad-1f5a689844ad",
        "key": "C",
        "text": "5.2"
      },
      {
        "id": "5c0fce38-216e-3efe-a96e-140bd69293fc",
        "key": "D",
        "text": "2.6, 13/5"
      }
    ],
    "correct_option_id": "5c0fce38-216e-3efe-a96e-140bd69293fc",
    "explanation": "The correct answer is 2.6 (or $\\frac{13}{5}$). Let $x$ represent the body weight in grams and $y$ represent the head width in millimeters. The model gives:\n$$y = 0.6 + 4x$$\nSubstituting $x = 0.5$:\n$$y = 0.6 + 4(0.5) = 0.6 + 2.0 = 2.6$$",
    "source_id": "e62cfe5f",
    "source_number": 46,
    "authored_distractors": true
  },
  {
    "id": "7dd5174e-0446-5c1d-9ada-bfcc7826290b",
    "external_key": "SAT_MATH:01682aa5",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
    "topic_name": "Algebra / Linear equations in two variables",
    "difficulty": "MEDIUM",
    "prompt": "Line $p$ is defined by $2y + 18x = 9$. Line $r$ is perpendicular to line $p$ in the $xy$-plane. What is the slope of line $r$?",
    "options": [
      {
        "id": "5b288510-aaec-3627-91c8-8c123f9c6371",
        "key": "A",
        "text": "$-9$"
      },
      {
        "id": "2d3a5d88-1602-3916-b3c8-1af706e39669",
        "key": "B",
        "text": "$-\\frac{1}{9}$"
      },
      {
        "id": "383a53e0-b6f1-30bb-8c81-6659f7283266",
        "key": "C",
        "text": "$\\frac{1}{9}$"
      },
      {
        "id": "b1eade19-a5fa-3dde-9b2e-1a476804afd5",
        "key": "D",
        "text": "9"
      }
    ],
    "correct_option_id": "383a53e0-b6f1-30bb-8c81-6659f7283266",
    "explanation": "Choice C is correct. Rewriting the equation of line $p$ in slope-intercept form:\n$$2y = -18x + 9 \\implies y = -9x + \\frac{9}{2}$$\nThe slope of line $p$ is $-9$. Since line $r$ is perpendicular to line $p$, its slope is the negative reciprocal:\n$$m_r = -\\frac{1}{-9} = \\frac{1}{9}$$",
    "source_id": "01682aa5",
    "source_number": 47,
    "authored_distractors": false
  },
  {
    "id": "9607f33a-ada1-5ac8-a086-3ade45910d14",
    "external_key": "SAT_MATH:9b0a4eae",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
    "topic_name": "Algebra / Linear equations in two variables",
    "difficulty": "MEDIUM",
    "prompt": "The graph in the $xy$-plane models the possible combinations of length $x$, in meters ($\text{m}$), and width $y$, in meters, for a rectangle with a perimeter of $36\\text{ m}$. Which statement is the best interpretation of the point $(8, 10)$ in this context?",
    "options": [
      {
        "id": "180a5618-9457-3606-9e4a-eb950a4e6512",
        "key": "A",
        "text": "The length is $10\\text{ m}$ less than the perimeter, and the width is $8\\text{ m}$ less than the perimeter."
      },
      {
        "id": "2d6ff3e0-b8aa-331b-acf0-f871c8aad229",
        "key": "B",
        "text": "The length is $10\\text{ m}$, and the width is $8\\text{ m}$."
      },
      {
        "id": "d781cfe4-3658-3ccf-90c0-999a6aeb02ce",
        "key": "C",
        "text": "The length is $8\\text{ m}$, and the width is $10\\text{ m}$."
      },
      {
        "id": "b3abd8bc-6f16-3219-ab9e-b09c543228f2",
        "key": "D",
        "text": "The length is $8\\text{ m}$ less than the perimeter, and the width is $10\\text{ m}$ less than the perimeter."
      }
    ],
    "correct_option_id": "d781cfe4-3658-3ccf-90c0-999a6aeb02ce",
    "explanation": "Choice C is correct. In this context, $x$ represents the length of the rectangle in meters and $y$ represents the width of the rectangle in meters. Thus, the coordinate $(8, 10)$ means that the rectangle has a length of $8\\text{ m}$ and a width of $10\\text{ m}$.",
    "source_id": "9b0a4eae",
    "source_number": 48,
    "authored_distractors": false
  },
  {
    "id": "ef75d3f1-d689-5d2c-aa7a-16cc810cf6ac",
    "external_key": "SAT_MATH:e142f83c",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "MEDIUM",
    "prompt": "$$y - 6 = \\frac{4}{5}(x + 5)$$\n$$y - v = \\frac{4}{5}(x + 10)$$\n\nIn the given system of equations, $v$ is a constant. The system has infinitely many solutions. What is the value of $v$?",
    "options": [
      {
        "id": "53075d1f-c27a-33b2-b8fd-57caeaf52451",
        "key": "A",
        "text": "0"
      },
      {
        "id": "2a753d38-a0a7-3ad3-b98d-b057bfea602d",
        "key": "B",
        "text": "2"
      },
      {
        "id": "3f8be9d9-6a6a-3667-be48-41a9fc8f7a87",
        "key": "C",
        "text": "4"
      },
      {
        "id": "86f4bb48-6f97-3a74-8703-954f76f0c538",
        "key": "D",
        "text": "12"
      }
    ],
    "correct_option_id": "2a753d38-a0a7-3ad3-b98d-b057bfea602d",
    "explanation": "Choice B is correct. A system of two linear equations has infinitely many solutions when the two equations represent the exact same line. Expanding the first equation:\n$$y = \\frac{4}{5}x + 4 + 6 \\implies y = \\frac{4}{5}x + 10$$\nExpanding the second equation:\n$$y = \\frac{4}{5}x + 8 + v$$\nFor the two equations to be equivalent, their constants must match:\n$$8 + v = 10 \\implies v = 2$$",
    "source_id": "e142f83c",
    "source_number": 49,
    "authored_distractors": false
  },
  {
    "id": "73aae206-4a53-5d83-8d70-1799318b7b14",
    "external_key": "SAT_MATH:e3cf671f",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "MEDIUM",
    "prompt": "The function $f$ is defined by $f(x) = 4x + k(x - 1)$, where $k$ is a constant, and $f(5) = 32$. What is the value of $f(10)$?",
    "options": [
      {
        "id": "32438235-9ccf-3313-9785-0aac074a794c",
        "key": "A",
        "text": "33"
      },
      {
        "id": "9e233eb2-6ed3-3b62-b5ed-658560d210b5",
        "key": "B",
        "text": "66"
      },
      {
        "id": "83d11bcd-9bbf-3300-84ee-8e9c862c6fda",
        "key": "C",
        "text": "134"
      },
      {
        "id": "5ebc533f-4f53-3939-aaed-64623a83d5bc",
        "key": "D",
        "text": "67"
      }
    ],
    "correct_option_id": "5ebc533f-4f53-3939-aaed-64623a83d5bc",
    "explanation": "The correct answer is 67. Substituting $x = 5$ into the definition of $f$:\n$$f(5) = 4(5) + k(5 - 1) = 20 + 4k$$\nSetting this equal to 32:\n$$20 + 4k = 32 \\implies 4k = 12 \\implies k = 3$$\nThus, the function is:\n$$f(x) = 4x + 3(x - 1) = 4x + 3x - 3 = 7x - 3$$\nEvaluating $f(10)$:\n$$f(10) = 7(10) - 3 = 70 - 3 = 67$$",
    "source_id": "e3cf671f",
    "source_number": 50,
    "authored_distractors": true
  },
  {
    "id": "2d2503f8-e3eb-5ecb-aa6f-e418242d2281",
    "external_key": "SAT_MATH:cb29c54c",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "A physics class is planning an experiment about a toy rocket. The equation $y = -16(x - 5.6)^2 + 502$ gives the estimated height $y$, in feet, of the toy rocket $x$ seconds after it is launched into the air. Which of the following is the best interpretation of the vertex of the graph of the equation in the $xy$-plane?",
    "options": [
      {
        "id": "d78167a2-c843-39e4-bde4-51949e598883",
        "key": "A",
        "text": "This toy rocket reaches an estimated maximum height of $502\\text{ feet } 16\\text{ seconds}$ after it is launched into the air."
      },
      {
        "id": "5390d393-a0bd-36b3-b669-cef20ea8127a",
        "key": "B",
        "text": "This toy rocket reaches an estimated maximum height of $502\\text{ feet } 5.6\\text{ seconds}$ after it is launched into the air."
      },
      {
        "id": "f96f58f8-fa3f-3c34-ae9e-cda187528dbd",
        "key": "C",
        "text": "This toy rocket reaches an estimated maximum height of $16\\text{ feet } 502\\text{ seconds}$ after it is launched into the air."
      },
      {
        "id": "a1bf6029-8977-3e03-8b76-2a3bcbac4cf7",
        "key": "D",
        "text": "This toy rocket reaches an estimated maximum height of $5.6\\text{ feet } 502\\text{ seconds}$ after it is launched into the air."
      }
    ],
    "correct_option_id": "5390d393-a0bd-36b3-b669-cef20ea8127a",
    "explanation": "Choice B is correct. In vertex form $y = a(x - h)^2 + k$, the vertex is $(h, k) = (5.6, 502)$. Because $a = -16 < 0$, the parabola opens downward, meaning the vertex represents the maximum value of $y$. In context, $x$ is time in seconds and $y$ is height in feet, so the toy rocket reaches an estimated maximum height of 502 feet 5.6 seconds after launch.",
    "source_id": "cb29c54c",
    "source_number": 51,
    "authored_distractors": false
  },
  {
    "id": "7369f3f5-de39-5c5b-b0e7-bc6dd91bf400",
    "external_key": "SAT_MATH:ad2ec615",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "MEDIUM",
    "prompt": "Which of the following is equivalent to the expression $x^4 - x^2 - 6$?",
    "options": [
      {
        "id": "fb09bedc-a175-3f21-aaf3-7dea6339569c",
        "key": "A",
        "text": "$(x^2 + 1)(x^2 - 6)$"
      },
      {
        "id": "6b6147b1-56b2-3404-989e-268a6a25b130",
        "key": "B",
        "text": "$(x^2 + 2)(x^2 - 3)$"
      },
      {
        "id": "0bb559be-c9a1-30ed-a56c-6c37a09982e8",
        "key": "C",
        "text": "$(x^2 + 3)(x^2 - 2)$"
      },
      {
        "id": "ca80813b-1ff1-319a-a46a-aa03d7b50cbd",
        "key": "D",
        "text": "$(x^2 + 6)(x^2 - 1)$"
      }
    ],
    "correct_option_id": "6b6147b1-56b2-3404-989e-268a6a25b130",
    "explanation": "Choice B is correct. Letting $u = x^2$, the expression becomes quadratic in $u$:\n$$u^2 - u - 6$$\nFactoring this quadratic yields two numbers whose product is $-6$ and sum is $-1$, which are $2$ and $-3$:\n$$(u + 2)(u - 3) = (x^2 + 2)(x^2 - 3)$$",
    "source_id": "ad2ec615",
    "source_number": 52,
    "authored_distractors": false
  },
  {
    "id": "ae143192-1ca2-51ae-93bb-153af3b05408",
    "external_key": "SAT_MATH:42c71eb5",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "MEDIUM",
    "prompt": "$$(2x + 5)^2 - (x - 2) + 2(x + 3)$$\n\nWhich of the following is equivalent to the expression above?",
    "options": [
      {
        "id": "540bf892-0e5f-3383-852d-4a0aad359716",
        "key": "A",
        "text": "$4x^2 + 21x + 33$"
      },
      {
        "id": "7f35326e-1995-3998-8699-d10ef7b296bd",
        "key": "B",
        "text": "$4x^2 + 21x + 29$"
      },
      {
        "id": "4790461d-d0e5-309f-94c2-6117c042f4a7",
        "key": "C",
        "text": "$4x^2 + x + 29$"
      },
      {
        "id": "0d446f44-7e8b-30a2-9a6f-7b24d57c8f78",
        "key": "D",
        "text": "$4x^2 + x + 33$"
      }
    ],
    "correct_option_id": "540bf892-0e5f-3383-852d-4a0aad359716",
    "explanation": "Choice A is correct. Expanding each part of the expression:\n$$(2x + 5)^2 = 4x^2 + 20x + 25$$\n$$-(x - 2) + 2(x + 3) = -x + 2 + 2x + 6 = x + 8$$\nCombining like terms:\n$$(4x^2 + 20x + 25) + (x + 8) = 4x^2 + (20x + x) + (25 + 8) = 4x^2 + 21x + 33$$",
    "source_id": "42c71eb5",
    "source_number": 53,
    "authored_distractors": false
  },
  {
    "id": "2b761acb-e1dc-521e-88ed-5779f2738080",
    "external_key": "SAT_MATH:52b1700c",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "| Time (years) | Total amount (dollars) |\n| :---: | :---: |\n| 0 | 604.00 |\n| 1 | 606.42 |\n| 2 | 608.84 |\n\nRosa opened a savings account at a bank. The table shows the exponential relationship between the time $t$, in years, since Rosa opened the account and the total amount $n$, in dollars, in the account. If Rosa made no additional deposits or withdrawals, which of the following equations best represents the relationship between $t$ and $n$?",
    "options": [
      {
        "id": "13673144-92ac-32d5-bd2e-52e90151b358",
        "key": "A",
        "text": "$n = (1 + 604)^t$"
      },
      {
        "id": "4c0a6918-fb67-30d1-88ad-a50b3b445075",
        "key": "B",
        "text": "$n = (1 + 0.004)^t$"
      },
      {
        "id": "8415622d-2de3-37d8-a2ed-0a3bc3333b84",
        "key": "C",
        "text": "$n = 604(1 + 0.004)^t$"
      },
      {
        "id": "a101611a-f62b-3369-8767-06adfc672d42",
        "key": "D",
        "text": "$n = 0.004(1 + 604)^t$"
      }
    ],
    "correct_option_id": "8415622d-2de3-37d8-a2ed-0a3bc3333b84",
    "explanation": "Choice C is correct. An exponential function can be modeled as $n = a(1 + r)^t$, where $a$ is the initial amount at $t = 0$. From the table, when $t = 0$, $n = 604.00$, so $a = 604$.\nWhen $t = 1$, $n = 606.42$:\n$$606.42 = 604(1 + r)^1 \\implies 1 + r = \\frac{606.42}{604} \\approx 1.004 \\implies r \\approx 0.004$$\nThus, the equation is $n = 604(1 + 0.004)^t$.",
    "source_id": "52b1700c",
    "source_number": 54,
    "authored_distractors": false
  },
  {
    "id": "437f1aa6-99f0-53d4-a12d-27c0a06f6625",
    "external_key": "SAT_MATH:b4acba95",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_EQUATIONS",
    "topic_name": "Advanced Math / Nonlinear equations in one variable and systems of equations in two variables",
    "difficulty": "MEDIUM",
    "prompt": "$$x^2 - 12x + 27 = 0$$\n\nHow many distinct real solutions does the given equation have?",
    "options": [
      {
        "id": "429a8266-c519-3087-b5bd-6b6431e38a74",
        "key": "A",
        "text": "Exactly two"
      },
      {
        "id": "b03d4bbf-0988-3251-a1a2-2dcdc59407f8",
        "key": "B",
        "text": "Exactly one"
      },
      {
        "id": "74b21212-f38f-366a-a4fe-2ef649aa14ad",
        "key": "C",
        "text": "Zero"
      },
      {
        "id": "7fa3251f-4b31-39ee-9e3e-1329f9d4f32a",
        "key": "D",
        "text": "Infinitely many"
      }
    ],
    "correct_option_id": "429a8266-c519-3087-b5bd-6b6431e38a74",
    "explanation": "Choice A is correct. The number of distinct real solutions to $ax^2 + bx + c = 0$ is determined by the discriminant $\\Delta = b^2 - 4ac$. Here, $a = 1, b = -12, c = 27$:\n$$\\Delta = (-12)^2 - 4(1)(27) = 144 - 108 = 36$$\nSince the discriminant is strictly positive ($\\Delta > 0$), the quadratic equation has exactly two distinct real solutions.",
    "source_id": "b4acba95",
    "source_number": 55,
    "authored_distractors": false
  },
  {
    "id": "b734d547-a9e4-5bf5-bd3f-bf312354976e",
    "external_key": "SAT_MATH:ff8c5844",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "| $x$ | $g(x)$ |\n| :---: | :---: |\n| $-1$ | 25 |\n| 0 | 1 |\n| 1 | $\\frac{1}{25}$ |\n| 2 | $\\frac{1}{625}$ |\n\nFor the exponential function $g$, the table shows four values of $x$ and their corresponding values of $g(x)$. Which equation defines $g$?",
    "options": [
      {
        "id": "213b396d-a900-3e83-ba4d-b3eafea0ff1d",
        "key": "A",
        "text": "$g(x) = -25^x$"
      },
      {
        "id": "23e6932a-5715-39f3-afa8-6a2e397e3b64",
        "key": "B",
        "text": "$g(x) = -(\\frac{1}{25})^x$"
      },
      {
        "id": "d0efc163-1170-32ae-ab85-1cd12c8840c9",
        "key": "C",
        "text": "$g(x) = 25^x$"
      },
      {
        "id": "73272039-fef7-3656-9223-a84dced70b81",
        "key": "D",
        "text": "$g(x) = (\\frac{1}{25})^x$"
      }
    ],
    "correct_option_id": "73272039-fef7-3656-9223-a84dced70b81",
    "explanation": "Choice D is correct. An exponential function can be written in the form $g(x) = a(b)^x$.\nFrom the table, $g(0) = 1 \\implies a(b)^0 = a = 1$.\nUsing $g(1) = \\frac{1}{25} \\implies 1(b)^1 = \\frac{1}{25} \\implies b = \\frac{1}{25}$.\nTherefore:\n$$g(x) = \\left(\\frac{1}{25}\\right)^x$$",
    "source_id": "ff8c5844",
    "source_number": 56,
    "authored_distractors": false
  },
  {
    "id": "abe53ce7-7e51-5e46-a833-76044d36d9a9",
    "external_key": "SAT_MATH:a05bd3a4",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "MEDIUM",
    "prompt": "Which of the following expressions is equivalent to $x^2 - 5$?",
    "options": [
      {
        "id": "821fe5f1-8307-30a4-b2cb-fe22b823d398",
        "key": "A",
        "text": "$(x + \\sqrt{5})^2$"
      },
      {
        "id": "3136d9c1-1e9e-32d4-b56f-b2669208e8bb",
        "key": "B",
        "text": "$(x - \\sqrt{5})^2$"
      },
      {
        "id": "52654109-1f04-3b52-95f0-0b96977588e8",
        "key": "C",
        "text": "$(x + \\sqrt{5})(x - \\sqrt{5})$"
      },
      {
        "id": "b1a6feb3-bc90-3841-84aa-f93bf55bbd53",
        "key": "D",
        "text": "$(x + 5)(x - 1)$"
      }
    ],
    "correct_option_id": "52654109-1f04-3b52-95f0-0b96977588e8",
    "explanation": "Choice C is correct. The expression $x^2 - 5$ can be factored as a difference of squares:\n$$a^2 - b^2 = (a + b)(a - b)$$\nHere, $a = x$ and $b = \\sqrt{5}$, giving:\n$$x^2 - 5 = (x + \\sqrt{5})(x - \\sqrt{5})$$",
    "source_id": "a05bd3a4",
    "source_number": 57,
    "authored_distractors": false
  },
  {
    "id": "3411e8fc-ff0c-5101-a90c-3e1e940f0537",
    "external_key": "SAT_MATH:f423771c",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "| $x$ | $h(x)$ |\n| :---: | :---: |\n| 0 | 1.23 |\n| 2 | 1.54 |\n| 4 | 1.94 |\n\nThe table shows the exponential relationship between the number of years, $x$, since Hana started training in pole vault, and the estimated height $h(x)$, in meters, of her best pole vault for that year. Which of the following functions best represents this relationship, where $x \\le 4$?",
    "options": [
      {
        "id": "25e0e41b-09ca-3e33-9eeb-c7afa24d728a",
        "key": "A",
        "text": "$h(x) = 1.12(0.23)^x$"
      },
      {
        "id": "700ce2e1-8a7a-3905-8b88-608c7188429d",
        "key": "B",
        "text": "$h(x) = 1.12(1.23)^x$"
      },
      {
        "id": "bc07463e-cd62-3c69-883b-bcd5564656f2",
        "key": "C",
        "text": "$h(x) = 1.23(0.12)^x$"
      },
      {
        "id": "155fb54f-e856-3e63-b7f2-4f523761490e",
        "key": "D",
        "text": "$h(x) = 1.23(1.12)^x$"
      }
    ],
    "correct_option_id": "155fb54f-e856-3e63-b7f2-4f523761490e",
    "explanation": "Choice D is correct. An exponential function can be modeled as $h(x) = Ca^x$.\nWhen $x = 0$, $h(0) = C = 1.23$.\nWhen $x = 2$, $h(2) = 1.23a^2 = 1.54$:\n$$a^2 = \\frac{1.54}{1.23} \\approx 1.252 \\implies a \\approx \\sqrt{1.252} \\approx 1.12$$\nTherefore, $h(x) = 1.23(1.12)^x$.",
    "source_id": "f423771c",
    "source_number": 58,
    "authored_distractors": false
  },
  {
    "id": "da487b6d-f75f-528c-90a4-89b6b56db5a0",
    "external_key": "SAT_MATH:1d3c5c95",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "$$f(x) = 4{,}000(0.75)^x$$\n\nAn entomologist recommended a program to reduce a certain invasive beetle population in an area. The given function estimates this beetle species' population $x$ years after 2012, where $x \\le 7$. Which of the following is the best interpretation of 4,000 in this context?",
    "options": [
      {
        "id": "c25f27cd-0b5c-30f1-867c-bb62058c260b",
        "key": "A",
        "text": "The estimated initial beetle population for this species and area in 2012"
      },
      {
        "id": "25b5d1b5-eec9-3a33-8a4b-e420ccfc198b",
        "key": "B",
        "text": "The estimated beetle population for this species and area 7 years after 2012"
      },
      {
        "id": "210dd40b-419b-38e3-b4e0-18daa26ef7e0",
        "key": "C",
        "text": "The estimated percent decrease in the beetle population for this species and area each year after 2012"
      },
      {
        "id": "c6d9f09b-a4b9-3175-991c-669ca57599a4",
        "key": "D",
        "text": "The estimated percent decrease in the beetle population for this species and area every 7 years after 2012"
      }
    ],
    "correct_option_id": "c25f27cd-0b5c-30f1-867c-bb62058c260b",
    "explanation": "Choice A is correct. In an exponential function of the form $f(x) = a(b)^x$, $a$ is the value of $f(x)$ when $x = 0$. Since $x$ represents the number of years after 2012, $x = 0$ corresponds to the year 2012. Therefore, 4,000 represents the estimated initial beetle population for this species and area in 2012.",
    "source_id": "1d3c5c95",
    "source_number": 59,
    "authored_distractors": false
  },
  {
    "id": "269cbe26-d474-5dd5-8cc1-11462d6bcdd6",
    "external_key": "SAT_MATH:ae05d37b",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "The function $f(t) = 40{,}000(2)^{\\frac{t}{790}}$ gives the number of bacteria in a population $t$ minutes after an initial observation. How much time, in minutes, does it take for the number of bacteria in the population to double?",
    "options": [
      {
        "id": "7a65275c-5192-3419-9a8e-c911f6ec0a90",
        "key": "A",
        "text": "2"
      },
      {
        "id": "af44d3ca-2dd0-33bb-9984-917dfe6130d2",
        "key": "B",
        "text": "790"
      },
      {
        "id": "49d5c0b0-1a44-3309-8146-90978ad35277",
        "key": "C",
        "text": "1,580"
      },
      {
        "id": "ead2b4f2-2973-3fc0-82a2-350a2a6fc91e",
        "key": "D",
        "text": "40,000"
      }
    ],
    "correct_option_id": "af44d3ca-2dd0-33bb-9984-917dfe6130d2",
    "explanation": "Choice B is correct. In the function $f(t) = 40{,}000(2)^{\\frac{t}{790}}$, the base is 2, representing doubling. The population doubles each time the exponent increases by 1:\n$$\\frac{t}{790} = 1 \\implies t = 790$$\nTherefore, it takes 790 minutes for the population of bacteria to double.",
    "source_id": "ae05d37b",
    "source_number": 60,
    "authored_distractors": false
  },
  {
    "id": "84ed3fba-33d4-5d49-b038-11fd20f71d88",
    "external_key": "SAT_MATH:405c5ced",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "MEDIUM",
    "prompt": "The function $C$ defined by $C(t) = 6(1.5)^t$ gives the estimated number of clients at a certain business, where $t$ is the number of weeks since the business opened. Which of the following is the best interpretation of the number $6$ in this context?",
    "options": [
      {
        "id": "c850841c-7dc5-3807-a1f7-23e3a0fe7a9e",
        "key": "A",
        "text": "The estimated number of clients when the business opened"
      },
      {
        "id": "3656a14e-bb47-3774-97d6-a886405a6e41",
        "key": "B",
        "text": "The increase in the estimated number of clients each week"
      },
      {
        "id": "f0529133-e9e8-3bcc-ba5c-a817395ceacb",
        "key": "C",
        "text": "The number of weeks the business has been open"
      },
      {
        "id": "1c58b85d-aa4f-3d43-ad02-88647298a73d",
        "key": "D",
        "text": "The percent increase in the estimated number of clients each week"
      }
    ],
    "correct_option_id": "c850841c-7dc5-3807-a1f7-23e3a0fe7a9e",
    "explanation": "Choice A is correct. For an exponential function of the form $C(t) = a(b)^t$, the constant $a$ represents the initial value of the function when $t = 0$. Since $t$ represents the number of weeks since the business opened, $t = 0$ corresponds to the moment the business opened. Evaluating $C(0) = 6(1.5)^0 = 6(1) = 6$. Therefore, $6$ is the estimated number of clients when the business opened.",
    "source_id": "405c5ced",
    "source_number": 61,
    "authored_distractors": false
  },
  {
    "id": "211aa3eb-7bae-5b0e-90f3-58f4b446cbcb",
    "external_key": "SAT_MATH:4b7bb316",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "MEDIUM",
    "prompt": "The length of each edge of a box is $29\\text{ inches}$. Each side of the box is in the shape of a square. The box does not have a lid. What is the exterior surface area, in square inches, of this box without a lid?",
    "options": [
      {
        "id": "4b1a4694-4846-3940-98a5-5900e5d60b08",
        "key": "A",
        "text": "405"
      },
      {
        "id": "2cd5ce68-2373-3bd4-ab13-b10bf389fe11",
        "key": "B",
        "text": "4200"
      },
      {
        "id": "f5da6277-6e97-3fae-9d09-de661d3789d4",
        "key": "C",
        "text": "4205"
      },
      {
        "id": "db4cee5f-5546-3fb2-95c0-30da2cb9f977",
        "key": "D",
        "text": "8405"
      }
    ],
    "correct_option_id": "f5da6277-6e97-3fae-9d09-de661d3789d4",
    "explanation": "The correct answer is 4,205. The box has no lid, so it consists of $5$ congruent square faces (the bottom base and 4 vertical sides).\nThe area of each square face is:\n$$\\text{Area of one face} = s^2 = 29^2 = 841\\text{ square inches}$$\nThe total exterior surface area of the box without a lid is:\n$$\\text{Surface Area} = 5 \\times 841 = 4{,}205\\text{ square inches}$$",
    "source_id": "4b7bb316",
    "source_number": 62,
    "authored_distractors": true
  },
  {
    "id": "6ae03557-66dc-5ce5-b76d-8d5a9bd89914",
    "external_key": "SAT_MATH:bcb66188",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "MEDIUM",
    "prompt": "Triangle $FGH$ is similar to triangle $JKL$, where angle $F$ corresponds to angle $J$ and angles $G$ and $K$ are right angles. If $\\sin(F) = \\frac{308}{317}$, what is the value of $\\sin(J)$?",
    "options": [
      {
        "id": "8b6f20eb-4f15-3289-a0dc-7b1415cd4f61",
        "key": "A",
        "text": "$\\frac{75}{317}$"
      },
      {
        "id": "810bee01-c4a3-33ef-8ef1-5b327935e40b",
        "key": "B",
        "text": "$\\frac{308}{317}$"
      },
      {
        "id": "2aa4d481-7040-397e-86a2-959266c369a7",
        "key": "C",
        "text": "$\\frac{317}{308}$"
      },
      {
        "id": "0363541a-ab48-39ef-b761-0bb45b68f6f7",
        "key": "D",
        "text": "$\\frac{317}{75}$"
      }
    ],
    "correct_option_id": "810bee01-c4a3-33ef-8ef1-5b327935e40b",
    "explanation": "Choice B is correct. If two triangles are similar, their corresponding angles are congruent. Since angle $F$ corresponds to angle $J$, $\\angle F \\cong \\angle J$, meaning $m\\angle F = m\\angle J$. The trigonometric ratios of congruent angles are equal, so:\n$$\\sin(J) = \\sin(F) = \\frac{308}{317}$$",
    "source_id": "bcb66188",
    "source_number": 63,
    "authored_distractors": false
  },
  {
    "id": "080ef5c3-c29f-598c-98dd-40bd43444400",
    "external_key": "SAT_MATH:3e4e2ab0",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "MEDIUM",
    "prompt": "In the figure, $\\overline{AE}$ intersects $\\overline{DB}$ at point $C$ and $\\overline{AB}$ is parallel to $\\overline{DE}$, creating triangles $ABC$ and $CDE$. In triangle $ABC$, the angle at $A$ has measure $y^\\circ$. In triangle $CDE$, angle $\\angle DCE$ has measure $x^\\circ$ and angle $\\angle CDE$ has measure $z^\\circ$. If $x = 63$ and $y = 2x - 47$, what is the value of $z$?",
    "options": [
      {
        "id": "80a5c05d-497b-3d2b-a270-830699cde594",
        "key": "A",
        "text": "38"
      },
      {
        "id": "365321ff-d36b-39c9-9054-3617f0e9490a",
        "key": "B",
        "text": "47"
      },
      {
        "id": "e4b59573-f42a-353e-8096-d3a9d6c33ddf",
        "key": "C",
        "text": "63"
      },
      {
        "id": "c4046d14-78de-39a4-a38e-68102785a9a7",
        "key": "D",
        "text": "79"
      }
    ],
    "correct_option_id": "80a5c05d-497b-3d2b-a270-830699cde594",
    "explanation": "Choice A is correct. Since $\\overline{AB} \\parallel \\overline{DE}$ with transversal $\\overline{AE}$, alternate interior angles $\\angle BAC$ and $\\angle DEC$ are congruent:\n$$m\\angle DEC = m\\angle BAC = y^\\circ$$\nWe are given that $x = 63$ and $y = 2x - 47$:\n$$y = 2(63) - 47 = 126 - 47 = 79$$\nThe interior angles of triangle $CDE$ are $\\angle DCE = x^\\circ = 63^\\circ$, $\\angle DEC = y^\\circ = 79^\\circ$, and $\\angle CDE = z^\\circ$. The angles of a triangle sum to $180^\\circ$:\n$$63 + 79 + z = 180 \\implies 142 + z = 180 \\implies z = 38$$",
    "source_id": "3e4e2ab0",
    "source_number": 64,
    "authored_distractors": false
  },
  {
    "id": "babefba5-90aa-52dc-a4c0-e448c312cc19",
    "external_key": "SAT_MATH:e89f63bf",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "MEDIUM",
    "prompt": "The sum of the measures of two angles in a triangle is $64^\\circ$. What is the measure of the third angle?",
    "options": [
      {
        "id": "44206686-65c4-3452-90af-2fb52322f76c",
        "key": "A",
        "text": "$26^\\circ$"
      },
      {
        "id": "de0cb7be-e445-3ace-a06b-f1c066120992",
        "key": "B",
        "text": "$52^\\circ$"
      },
      {
        "id": "4d28eb40-b84e-3f53-b9f8-72b4b9f809c2",
        "key": "C",
        "text": "$116^\\circ$"
      },
      {
        "id": "2cd9202f-9b0f-3fbc-ab54-21ed85aea391",
        "key": "D",
        "text": "$128^\\circ$"
      }
    ],
    "correct_option_id": "4d28eb40-b84e-3f53-b9f8-72b4b9f809c2",
    "explanation": "Choice C is correct. The sum of the measures of all three angles in any triangle is $180^\\circ$. If the sum of two angles is $64^\\circ$, the measure of the third angle is:\n$$180^\\circ - 64^\\circ = 116^\\circ$$",
    "source_id": "e89f63bf",
    "source_number": 65,
    "authored_distractors": false
  },
  {
    "id": "cc472fe6-9980-5d08-9d77-1204b4a38674",
    "external_key": "SAT_MATH:f67e4efc",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "MEDIUM",
    "prompt": "A right circular cylinder has a volume of $45\\pi$. If the height of the cylinder is 5, what is the radius of the cylinder?",
    "options": [
      {
        "id": "1432424f-dc15-361a-89e9-1167d36ce22d",
        "key": "A",
        "text": "3"
      },
      {
        "id": "cb8ec0af-1afd-3b1d-8a46-661a52115821",
        "key": "B",
        "text": "4.5"
      },
      {
        "id": "859c1e70-ce7d-3ef3-8ccd-b5c5c7b040f1",
        "key": "C",
        "text": "9"
      },
      {
        "id": "76088f7a-bca6-36fb-8b55-9bd5c3eca64f",
        "key": "D",
        "text": "40"
      }
    ],
    "correct_option_id": "1432424f-dc15-361a-89e9-1167d36ce22d",
    "explanation": "Choice A is correct. The volume of a right circular cylinder is given by $V = \\pi r^2 h$. Substituting $V = 45\\pi$ and $h = 5$:\n$$45\\pi = \\pi r^2(5)$$\nDividing both sides by $5\\pi$:\n$$9 = r^2$$\nTaking the square root (since radius must be positive):\n$$r = 3$$",
    "source_id": "f67e4efc",
    "source_number": 66,
    "authored_distractors": false
  },
  {
    "id": "741a8c76-8242-5d11-8a08-f6418e71e985",
    "external_key": "SAT_MATH:ecc98c87",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "MEDIUM",
    "prompt": "In the figure shown, line $k$ intersects lines $r$ and $s$. At the intersection with line $r$, the angles are $w^\\circ$ and $x^\\circ$. At the intersection with line $s$, the angles are $y^\\circ$ and $z^\\circ$. If $w = 147$, which additional piece of information is sufficient to prove that lines $r$ and $s$ are parallel?",
    "options": [
      {
        "id": "772d7923-e3b4-39b8-b412-67cea2d78da7",
        "key": "A",
        "text": "$x = 33$"
      },
      {
        "id": "8253aa0f-f0f3-3f28-8d32-977795035f81",
        "key": "B",
        "text": "$y = 147$"
      },
      {
        "id": "e39fc8f3-493c-3460-8f1a-9b8ef3e701fa",
        "key": "C",
        "text": "$w + y = 180$"
      },
      {
        "id": "0408d712-89b2-3531-88b2-7329bf7546e7",
        "key": "D",
        "text": "$y + z = 180$"
      }
    ],
    "correct_option_id": "8253aa0f-f0f3-3f28-8d32-977795035f81",
    "explanation": "Choice B is correct. In the figure, the angles labeled $w^\\circ$ and $y^\\circ$ occupy the same relative position at each intersection, making them corresponding angles. Lines $r$ and $s$ cut by transversal $k$ are parallel if and only if corresponding angles are congruent ($w = y$). Since $w = 147$, knowing that $y = 147$ establishes that $w = y$, which is sufficient to prove that lines $r$ and $s$ are parallel.",
    "source_id": "ecc98c87",
    "source_number": 67,
    "authored_distractors": false
  },
  {
    "id": "4ead5631-0d22-59ac-880b-aa698326d4b5",
    "external_key": "SAT_MATH:33e29881",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "MEDIUM",
    "prompt": "In right triangle $RST$, the sum of the measures of angle $R$ and angle $S$ is $90\\text{ degrees}$. The value of $\\sin(R)$ is $\\frac{\\sqrt{15}}{4}$. What is the value of $\\cos(S)$?",
    "options": [
      {
        "id": "c86b3ade-a53c-348a-b3c8-ea93f7eae10d",
        "key": "A",
        "text": "$\\frac{\\sqrt{15}}{15}$"
      },
      {
        "id": "04d1ff94-3a55-3041-8923-c947d47695b6",
        "key": "B",
        "text": "$\\frac{\\sqrt{15}}{4}$"
      },
      {
        "id": "66f094e4-f783-3fed-92d1-f2a121693786",
        "key": "C",
        "text": "$\\frac{4\\sqrt{15}}{15}$"
      },
      {
        "id": "7bdf33df-0d0a-39f8-9fe9-2f6b43a7f34a",
        "key": "D",
        "text": "$\\sqrt{15}$"
      }
    ],
    "correct_option_id": "04d1ff94-3a55-3041-8923-c947d47695b6",
    "explanation": "Choice B is correct. The sine of any acute angle is equal to the cosine of its complementary angle. Since $m\\angle R + m\\angle S = 90^\\circ$, angles $R$ and $S$ are complementary. Therefore:\n$$\\cos(S) = \\sin(R) = \\frac{\\sqrt{15}}{4}$$",
    "source_id": "33e29881",
    "source_number": 68,
    "authored_distractors": false
  },
  {
    "id": "3eb53f64-aa4b-5317-9e7c-695a2a9b03ea",
    "external_key": "SAT_MATH:5afbdc8e",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "MEDIUM",
    "prompt": "What is the length of one side of a square that has the same area as a circle with radius 2?",
    "options": [
      {
        "id": "4b0d735d-cdbc-3bb6-9603-4fa3e4d40edd",
        "key": "A",
        "text": "2"
      },
      {
        "id": "07f73800-4792-3b80-a020-0c6d03068203",
        "key": "B",
        "text": "$\\sqrt{2\\pi}$"
      },
      {
        "id": "b34d2e56-cd35-3c09-a534-91dd43d3e0e5",
        "key": "C",
        "text": "$2\\sqrt{\\pi}$"
      },
      {
        "id": "ed395227-6073-3d22-bccd-fbcb353cb8a8",
        "key": "D",
        "text": "$2\\pi$"
      }
    ],
    "correct_option_id": "b34d2e56-cd35-3c09-a534-91dd43d3e0e5",
    "explanation": "Choice C is correct. The area of a circle with radius $r = 2$ is:\n$$A_{\\text{circle}} = \\pi r^2 = \\pi(2^2) = 4\\pi$$\nLet $s$ be the side length of the square. Since the square has the same area as the circle:\n$$s^2 = 4\\pi$$\nTaking the square root of both sides (since side length must be positive):\n$$s = \\sqrt{4\\pi} = \\sqrt{4}\\sqrt{\\pi} = 2\\sqrt{\\pi}$$",
    "source_id": "5afbdc8e",
    "source_number": 69,
    "authored_distractors": false
  },
  {
    "id": "e5c13f4a-bbe7-57b3-9d68-261a0aeb212f",
    "external_key": "SAT_MATH:659cb706",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "MEDIUM",
    "prompt": "Triangle $XYZ$ shown is a right triangle with right angle at $Z$, leg $XZ = 27$, and leg $YZ = 35$. Which of the following has the same value as $\\sin X$?",
    "options": [
      {
        "id": "f4346f37-0e98-3b5c-970b-3a710480823f",
        "key": "A",
        "text": "$\\tan X$"
      },
      {
        "id": "e21d1374-3ab6-383a-be50-9e2d85d5a15a",
        "key": "B",
        "text": "$\\tan Y$"
      },
      {
        "id": "5e7e42cb-41ae-397d-b2e8-cc11ca2645bc",
        "key": "C",
        "text": "$\\cos X$"
      },
      {
        "id": "cee862b0-9035-3688-b7cb-7c8e1d3b6e03",
        "key": "D",
        "text": "$\\cos Y$"
      }
    ],
    "correct_option_id": "cee862b0-9035-3688-b7cb-7c8e1d3b6e03",
    "explanation": "Choice D is correct. In a right triangle, the two acute angles are complementary: $m\\angle X + m\\angle Y = 90^\\circ$. By trigonometric cofunction identities, the sine of an acute angle is always equal to the cosine of its complement:\n$$\\sin X = \\frac{\\text{opposite}}{\\text{hypotenuse}} = \\frac{YZ}{XY} = \\cos Y$$\nTherefore, $\\cos Y$ has the same value as $\\sin X$.",
    "source_id": "659cb706",
    "source_number": 70,
    "authored_distractors": false
  },
  {
    "id": "13410520-4bd0-5440-a5cd-b0cc5a6a9d03",
    "external_key": "SAT_MATH:46b2e169",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PROBABILITY",
    "topic_name": "Problem-Solving and Data Analysis / Probability and conditional probability",
    "difficulty": "MEDIUM",
    "prompt": "A box contains $13\\text{ red pens}$ and $37\\text{ blue pens}$. If one of these pens is selected at random, what is the probability of selecting a red pen? (Express your answer as a decimal or fraction, not as a percent.)",
    "options": [
      {
        "id": "4d1af0ff-5138-36e3-9c0d-5487d8fb5341",
        "key": "A",
        "text": "0.13"
      },
      {
        "id": "c29de5d8-642f-320d-b13a-efdea1763aae",
        "key": "B",
        "text": ".26, 13/50"
      },
      {
        "id": "06da16f1-d397-3e0f-8d68-fd66ecdc7971",
        "key": "C",
        "text": "0.52"
      },
      {
        "id": "722dac7f-1d19-30ae-9c26-2bd51d74c2f7",
        "key": "D",
        "text": "50/13"
      }
    ],
    "correct_option_id": "c29de5d8-642f-320d-b13a-efdea1763aae",
    "explanation": "The correct answer is $\\frac{13}{50}$ (or $.26$). The total number of pens in the box is:\n$$13 + 37 = 50$$\nThe probability of randomly selecting a red pen is the number of red pens divided by the total number of pens:\n$$P(\\text{red pen}) = \\frac{13}{50} = 0.26$$",
    "source_id": "46b2e169",
    "source_number": 71,
    "authored_distractors": true
  },
  {
    "id": "f875619b-51cd-5d93-a2c1-589bb353e1f3",
    "external_key": "SAT_MATH:f8696cd8",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PROBABILITY",
    "topic_name": "Problem-Solving and Data Analysis / Probability and conditional probability",
    "difficulty": "MEDIUM",
    "prompt": "| | Human Resources | Accounting |\n| :--- | :---: | :---: |\n| **Bachelor's degree** | 4 | 3 |\n| **Master's degree** | 2 | 6 |\n\nThe table above shows the number of people who work in the Human Resources and Accounting departments of a company and the highest level of education they have completed. A person from one of these departments is to be chosen at random. If the person chosen works in the Human Resources department, what is the probability that the highest level of education the person completed is a master's degree?",
    "options": [
      {
        "id": "bf336efa-c518-38f6-8bd8-2356802f6a18",
        "key": "A",
        "text": "$\\frac{2}{15}$"
      },
      {
        "id": "c91cf788-1614-3537-a8aa-fcacb2b7472e",
        "key": "B",
        "text": "$\\frac{1}{3}$"
      },
      {
        "id": "0cda171c-08e0-335b-8790-ad1eb39a21ee",
        "key": "C",
        "text": "$\\frac{1}{4}$"
      },
      {
        "id": "7bbd5e35-8688-3123-888b-7e5f4e5d7000",
        "key": "D",
        "text": "$\\frac{8}{15}$"
      }
    ],
    "correct_option_id": "c91cf788-1614-3537-a8aa-fcacb2b7472e",
    "explanation": "Choice B is correct. We are given the condition that the chosen person works in the Human Resources department.\n- Total number of people in Human Resources: $4 + 2 = 6$.\n- Number of people in Human Resources with a master's degree: $2$.\nThe conditional probability is:\n$$P(\\text{master's degree} \\mid \\text{Human Resources}) = \\frac{2}{6} = \\frac{1}{3}$$",
    "source_id": "f8696cd8",
    "source_number": 72,
    "authored_distractors": false
  },
  {
    "id": "06573038-109d-5929-bfb4-d1e5e9eb4e5e",
    "external_key": "SAT_MATH:50b2807e",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_TWO_VARIABLES",
    "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
    "difficulty": "MEDIUM",
    "prompt": "The scatterplot shows the relationship between two variables, $x$ and $y$. As $x$ increases from 1 to 10, $y$ decreases from approximately 9 to approximately 1. Which of the following equations is the most appropriate linear model for the data shown?",
    "options": [
      {
        "id": "0d0bd530-75ef-3a16-aa52-1235f4a59cdf",
        "key": "A",
        "text": "$y = 0.9 + 9.4x$"
      },
      {
        "id": "b4813cf1-4553-3dcb-bc90-c6efd546e521",
        "key": "B",
        "text": "$y = 0.9 - 9.4x$"
      },
      {
        "id": "1e762cd8-6554-3659-b37a-72568c680d67",
        "key": "C",
        "text": "$y = 9.4 + 0.9x$"
      },
      {
        "id": "28a8e528-5607-3f3d-b2bb-6b2a49e4c5b7",
        "key": "D",
        "text": "$y = 9.4 - 0.9x$"
      }
    ],
    "correct_option_id": "28a8e528-5607-3f3d-b2bb-6b2a49e4c5b7",
    "explanation": "Choice D is correct. Looking at the scatterplot:\n- As $x$ increases, $y$ decreases, which indicates a negative slope ($b < 0$).\n- When $x = 0$, the $y$-intercept is above $9$ (approximately $9.4$).\nAmong the given options:\n- Choices A and C have positive slopes.\n- Choice B has a $y$-intercept of $0.9$, which is far too low.\n- Choice D has a $y$-intercept of $9.4$ and a negative slope of $-0.9$, fitting the data points: for example, when $x = 5$, $y \\approx 9.4 - 0.9(5) = 4.9$, matching the observed point $(5, 5)$.",
    "source_id": "50b2807e",
    "source_number": 73,
    "authored_distractors": false
  },
  {
    "id": "b77a7801-fdc7-5b7a-9a87-93097926068d",
    "external_key": "SAT_MATH:24a1e6a7",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_TWO_VARIABLES",
    "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
    "difficulty": "MEDIUM",
    "prompt": "The scatterplot shows the relationship between two variables, $x$ and $y$. A line of best fit is also shown, passing approximately through $(0, 14)$ and $(13, 0)$. Which of the following is closest to the slope of this line of best fit?",
    "options": [
      {
        "id": "8b40c9cf-fd47-3dbc-ad94-87e8b74231df",
        "key": "A",
        "text": "$-3.3$"
      },
      {
        "id": "c8f634b0-f0f4-3991-b6cc-8b4582bc8970",
        "key": "B",
        "text": "$-1.1$"
      },
      {
        "id": "e41a4f12-c5e0-3c7b-8c3e-65b40b3f1f4c",
        "key": "C",
        "text": "1.1"
      },
      {
        "id": "c87d15fe-1ff7-3b04-845b-6bb244925085",
        "key": "D",
        "text": "3.3"
      }
    ],
    "correct_option_id": "c8f634b0-f0f4-3991-b6cc-8b4582bc8970",
    "explanation": "Choice B is correct. Using the two points $(0, 14)$ and $(13, 0)$ on the line of best fit, the slope $m$ is:\n$$m = \\frac{0 - 14}{13 - 0} = -\\frac{14}{13} \\approx -1.077$$\nAmong the choices, $-1.1$ is closest to $-1.077$.",
    "source_id": "24a1e6a7",
    "source_number": 74,
    "authored_distractors": false
  },
  {
    "id": "6b8f3db8-2d66-5c77-8347-23e614952364",
    "external_key": "SAT_MATH:81d0f1e6",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_RATIOS_RATES_UNITS",
    "topic_name": "Problem-Solving and Data Analysis / Ratios, rates, proportional relationships, and units",
    "difficulty": "MEDIUM",
    "prompt": "The ratio $a$ to $b$ is equivalent to the ratio $63$ to $17$. What is the value of $a$ when $b = 153$?",
    "options": [
      {
        "id": "8673e5ef-6f6c-3b6c-8f12-525228c12a91",
        "key": "A",
        "text": "189"
      },
      {
        "id": "01554fa6-48b0-3c0f-aa9b-b96cee6aa6d7",
        "key": "B",
        "text": "378"
      },
      {
        "id": "aed9fdd3-4dec-3576-b542-622779b34c16",
        "key": "C",
        "text": "567"
      },
      {
        "id": "d1154a3d-cd07-34c3-9011-8970e702ceee",
        "key": "D",
        "text": "1134"
      }
    ],
    "correct_option_id": "aed9fdd3-4dec-3576-b542-622779b34c16",
    "explanation": "The correct answer is 567. The proportion between the quantities can be written as:\n$$\\frac{a}{b} = \\frac{63}{17}$$\nSubstituting $b = 153$:\n$$\\frac{a}{153} = \\frac{63}{17}$$\nMultiplying both sides by 153:\n$$a = 153 \\times \\frac{63}{17} = (153 \\div 17) \\times 63 = 9 \\times 63 = 567$$",
    "source_id": "81d0f1e6",
    "source_number": 75,
    "authored_distractors": true
  },
  {
    "id": "ee85134b-c393-5c6b-a65a-bab2ffedff63",
    "external_key": "SAT_MATH:58171b5e",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_TWO_VARIABLES",
    "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
    "difficulty": "MEDIUM",
    "prompt": "Each year, the value of an investment increases by $0.49\\%$ of its value the previous year. Which of the following functions best models how the value of the investment changes over time?",
    "options": [
      {
        "id": "1386b24b-2d4e-3015-845a-1d2f8c440d9c",
        "key": "A",
        "text": "Decreasing exponential"
      },
      {
        "id": "10a1db7e-3bb7-3575-a6f1-05a796ac1fe9",
        "key": "B",
        "text": "Decreasing linear"
      },
      {
        "id": "6e0ddc8b-97c7-373d-be84-ef669144e509",
        "key": "C",
        "text": "Increasing exponential"
      },
      {
        "id": "3e036419-f64e-3b45-bf8e-cac1cc7913a3",
        "key": "D",
        "text": "Increasing linear"
      }
    ],
    "correct_option_id": "6e0ddc8b-97c7-373d-be84-ef669144e509",
    "explanation": "Choice C is correct.\n- Because the investment increases in value, it is modeled by an increasing function.\n- Because the increase is by a fixed percentage ($0.49\\%$) of the previous year's value each year rather than by a fixed constant amount, the growth is multiplicative rather than additive.\nA quantity that changes by a constant percentage over equal time intervals is modeled by an exponential function. Therefore, the function is an increasing exponential function.",
    "source_id": "58171b5e",
    "source_number": 76,
    "authored_distractors": false
  },
  {
    "id": "4a3d501d-205a-5c7a-8a86-a69b5cb955ca",
    "external_key": "SAT_MATH:51c9d65f",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_RATIOS_RATES_UNITS",
    "topic_name": "Problem-Solving and Data Analysis / Ratios, rates, proportional relationships, and units",
    "difficulty": "MEDIUM",
    "prompt": "For a certain rectangular region, the ratio of its length to its width is $35$ to $10$. If the width of the rectangular region increases by $7\\text{ units}$, how must the length change to maintain this ratio?",
    "options": [
      {
        "id": "392987f2-d566-3e9a-a432-656d7e963c33",
        "key": "A",
        "text": "It must decrease by $24.5\\text{ units}$."
      },
      {
        "id": "dd3be0c2-0eb3-3397-b1bb-58836ad41892",
        "key": "B",
        "text": "It must increase by $24.5\\text{ units}$."
      },
      {
        "id": "d11ad4a1-2565-3055-8634-ea345d91df49",
        "key": "C",
        "text": "It must decrease by $7\\text{ units}$."
      },
      {
        "id": "200b9b20-61be-38c7-955a-e5b9b3e58473",
        "key": "D",
        "text": "It must increase by $7\\text{ units}$."
      }
    ],
    "correct_option_id": "dd3be0c2-0eb3-3397-b1bb-58836ad41892",
    "explanation": "Choice B is correct. The ratio of length $\\ell$ to width $w$ is:\n$$\\frac{\\ell}{w} = \\frac{35}{10} = 3.5 \\implies \\ell = 3.5w$$\nIf the width increases by $7\\text{ units}$, the new width is $w + 7$. To maintain the same ratio, the new length $\\ell_{\\text{new}}$ must satisfy:\n$$\\ell_{\\text{new}} = 3.5(w + 7) = 3.5w + 3.5(7) = 3.5w + 24.5$$\nSince the original length is $\\ell = 3.5w$:\n$$\\ell_{\\text{new}} = \\ell + 24.5$$\nThus, the length must increase by $24.5\\text{ units}$.",
    "source_id": "51c9d65f",
    "source_number": 77,
    "authored_distractors": false
  },
  {
    "id": "26df5954-d578-5ba4-a83c-15acfd0d3b5a",
    "external_key": "SAT_MATH:25fc031a",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "MEDIUM",
    "prompt": "The histograms summarize the distributions of number of units sold, in thousands, for company A and company B. Company A has high frequencies concentrated tightly around the center ($30-35\\text{ thousand}$), whereas Company B has higher frequencies spread out toward the outer ends ($15-20$ and $45-50\\text{ thousand}$). Which statement best compares the standard deviations of number of units sold for these companies?",
    "options": [
      {
        "id": "c29edd3c-a118-3c02-870a-21231ac92a56",
        "key": "A",
        "text": "The standard deviation of number of units sold for company A is less than the standard deviation of number of units sold for company B."
      },
      {
        "id": "a883d544-f7cc-37dc-9f0e-1d0985b953b3",
        "key": "B",
        "text": "The standard deviation of number of units sold for company A is greater than the standard deviation of number of units sold for company B."
      },
      {
        "id": "c373c2e6-c910-34a9-acad-12f51246f133",
        "key": "C",
        "text": "The standard deviation of number of units sold for company A is equal to the standard deviation of number of units sold for company B."
      },
      {
        "id": "b97e521e-eb21-3fe7-be90-c4d459818419",
        "key": "D",
        "text": "There is not enough information to compare the standard deviations."
      }
    ],
    "correct_option_id": "c29edd3c-a118-3c02-870a-21231ac92a56",
    "explanation": "Choice A is correct. Standard deviation measures the spread or dispersion of a dataset around its mean.\n- Both histograms are symmetric with the same center (mean between 30 and 35 thousand).\n- In company A's histogram, data values are heavily concentrated near the mean, indicating low variability and a smaller standard deviation.\n- In company B's histogram, substantial proportions of data values are located in the outer tails farther from the mean, indicating higher variability and a larger standard deviation.\nTherefore, the standard deviation of company A is less than the standard deviation of company B.",
    "source_id": "25fc031a",
    "source_number": 78,
    "authored_distractors": false
  },
  {
    "id": "970c315e-4c93-51ff-a152-f2f00be8cbc6",
    "external_key": "SAT_MATH:d72a2b4d",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PERCENTAGES",
    "topic_name": "Problem-Solving and Data Analysis / Percentages",
    "difficulty": "MEDIUM",
    "prompt": "In March, the price of a collectible card was $\\$15.50$. In April, the price of the collectible card was $\\$17.36$. The price of the collectible card in April was $p\\%$ of the price of the collectible card in March. What is the value of $p$?",
    "options": [
      {
        "id": "c8ba3c26-e3c5-3fc7-b808-472f3d45c75c",
        "key": "A",
        "text": "12"
      },
      {
        "id": "cfacd53e-dce8-3bbb-b3ee-8279772cb52d",
        "key": "B",
        "text": "88"
      },
      {
        "id": "0c1ef315-53c9-3723-84b6-0a26b13462bc",
        "key": "C",
        "text": "112"
      },
      {
        "id": "2b92d251-5707-3b11-834c-1ca405336003",
        "key": "D",
        "text": "188"
      }
    ],
    "correct_option_id": "0c1ef315-53c9-3723-84b6-0a26b13462bc",
    "explanation": "Choice C is correct. The problem states that the April price was $p\\%$ of the March price:\n$$17.36 = \\frac{p}{100} \\times 15.50$$\nMultiplying both sides by 100:\n$$1{,}736 = 15.50p$$\nDividing both sides by 15.50:\n$$p = \\frac{1{,}736}{15.50} = 112$$",
    "source_id": "d72a2b4d",
    "source_number": 79,
    "authored_distractors": false
  },
  {
    "id": "2336d78e-b126-5f8e-aa91-7f943f8d48de",
    "external_key": "SAT_MATH:e9ed719f",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PROBABILITY",
    "topic_name": "Problem-Solving and Data Analysis / Probability and conditional probability",
    "difficulty": "MEDIUM",
    "prompt": "The table summarizes the distribution of color and shape for $100\\text{ tiles}$ of equal area:\n\n| | Red | Blue | Yellow | Total |\n| :--- | :---: | :---: | :---: | :---: |\n| **Square** | 10 | 20 | 25 | 55 |\n| **Pentagon** | 20 | 10 | 15 | 45 |\n| **Total** | 30 | 30 | 40 | 100 |\n\nIf one of these tiles is selected at random, what is the probability of selecting a red tile? (Express your answer as a decimal or fraction, not as a percent.)",
    "options": [
      {
        "id": "c6298e7b-a052-3a3f-8154-d6b5b9912e46",
        "key": "A",
        "text": "0.03"
      },
      {
        "id": "bc3ea668-cb5c-321a-b107-9bbf7e0d5900",
        "key": "B",
        "text": "0.6"
      },
      {
        "id": "8239f75e-c94e-38b2-98cd-1e05311c06d2",
        "key": "C",
        "text": "3"
      },
      {
        "id": "022c988c-bc5a-33bd-9736-0935d0a9b692",
        "key": "D",
        "text": "0.3, 3/10"
      }
    ],
    "correct_option_id": "022c988c-bc5a-33bd-9736-0935d0a9b692",
    "explanation": "The correct answer is $\\frac{3}{10}$ (or $0.3$).\n- Total number of red tiles: $10 + 20 = 30$.\n- Total number of tiles: $100$.\nThe probability of selecting a red tile is:\n$$P(\\text{Red}) = \\frac{30}{100} = \\frac{3}{10} = 0.3$$",
    "source_id": "e9ed719f",
    "source_number": 80,
    "authored_distractors": true
  },
  {
    "id": "8704fb4b-2c09-5e71-ad61-883fa486da92",
    "external_key": "SAT_MATH:3d1070c9",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "EASY",
    "prompt": "The function $f$ is defined by $f(x) = 25x + 30$. What is the value of $f(x)$ when $x = 2$?",
    "options": [
      {
        "id": "80c90426-2785-341c-87c1-0691f3469483",
        "key": "A",
        "text": "50"
      },
      {
        "id": "df8b0dda-fdf4-3164-9824-a9c75f32e16f",
        "key": "B",
        "text": "57"
      },
      {
        "id": "a5177642-86f3-336e-a05f-912a647c184c",
        "key": "C",
        "text": "80"
      },
      {
        "id": "41593de4-353c-3b22-8e4e-00f08005fb4d",
        "key": "D",
        "text": "110"
      }
    ],
    "correct_option_id": "a5177642-86f3-336e-a05f-912a647c184c",
    "explanation": "Choice C is correct. Substituting $x = 2$ into the given function:\n$$f(2) = 25(2) + 30 = 50 + 30 = 80$$",
    "source_id": "3d1070c9",
    "source_number": 81,
    "authored_distractors": false
  },
  {
    "id": "73f42366-ae5a-500a-aafe-8332ef31fb1a",
    "external_key": "SAT_MATH:fa80893a",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_ONE_VARIABLE",
    "topic_name": "Algebra / Linear equations in one variable",
    "difficulty": "EASY",
    "prompt": "If $2x + 3 = 9$, what is the value of $6x - 1$?",
    "options": [
      {
        "id": "937a9494-e198-34a7-95cb-ee90c640365d",
        "key": "A",
        "text": "8"
      },
      {
        "id": "ed2b3363-654b-3ba7-8bca-53e124aeb4e8",
        "key": "B",
        "text": "16"
      },
      {
        "id": "f1dcf94c-1df4-3f92-8835-f56a369b8903",
        "key": "C",
        "text": "17"
      },
      {
        "id": "e894a47b-b0a3-3af0-a0cc-746ef963eeae",
        "key": "D",
        "text": "34"
      }
    ],
    "correct_option_id": "f1dcf94c-1df4-3f92-8835-f56a369b8903",
    "explanation": "The correct answer is 17. Solving for $x$:\n$$2x + 3 = 9 \\implies 2x = 6 \\implies x = 3$$\nSubstituting $x = 3$ into $6x - 1$:\n$$6(3) - 1 = 18 - 1 = 17$$\nAlternatively, multiplying both sides of $2x + 3 = 9$ by 3 gives $6x + 9 = 27$. Subtracting 10 from both sides yields $6x - 1 = 17$.",
    "source_id": "fa80893a",
    "source_number": 82,
    "authored_distractors": true
  },
  {
    "id": "4f23baf4-4c86-5bae-9472-b29df8d79a40",
    "external_key": "SAT_MATH:bd9eb2b5",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "EASY",
    "prompt": "The function $f$ is defined by $f(x) = 8x$. For what value of $x$ does $f(x) = 72$?",
    "options": [
      {
        "id": "2a3cf303-6621-30bc-b657-dd483674e39b",
        "key": "A",
        "text": "8"
      },
      {
        "id": "8d26e088-d3b8-33d6-957d-29cf9168274d",
        "key": "B",
        "text": "9"
      },
      {
        "id": "28deb799-970a-3221-859f-9d2c4df5720a",
        "key": "C",
        "text": "64"
      },
      {
        "id": "3669e19e-752a-3b3e-9b8c-de9283d976d0",
        "key": "D",
        "text": "80"
      }
    ],
    "correct_option_id": "8d26e088-d3b8-33d6-957d-29cf9168274d",
    "explanation": "Choice B is correct. Setting $f(x) = 72$:\n$$8x = 72 \\implies x = \\frac{72}{8} = 9$$",
    "source_id": "bd9eb2b5",
    "source_number": 83,
    "authored_distractors": false
  },
  {
    "id": "b18a27a6-41ce-524b-b022-b4fd16777f34",
    "external_key": "SAT_MATH:0d6ab461",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "EASY",
    "prompt": "Gabriella deposits $\\$35$ in a savings account at the end of each week. At the beginning of the 1st week of a year there was $\\$600$ in that savings account. How much money, in dollars, will be in the account at the end of the 4th week of that year?",
    "options": [
      {
        "id": "0a6e0434-49aa-3fa4-bc3a-91e2b966f19b",
        "key": "A",
        "text": "460"
      },
      {
        "id": "ede49698-7f83-3c4e-b84e-8b937255ae5c",
        "key": "B",
        "text": "635"
      },
      {
        "id": "e0686cc6-fe17-3cf5-95ff-eac370f5abeb",
        "key": "C",
        "text": "639"
      },
      {
        "id": "295595b7-df71-3e2b-bba6-14b2ec6bcf5b",
        "key": "D",
        "text": "740"
      }
    ],
    "correct_option_id": "295595b7-df71-3e2b-bba6-14b2ec6bcf5b",
    "explanation": "Choice D is correct. Over 4 weeks, Gabriella makes 4 deposits of $\\$35$:\n$$4 \\times 35 = 140\\text{ dollars}$$\nAdding this to the initial account balance of $\\$600$:\n$$600 + 140 = 740\\text{ dollars}$$",
    "source_id": "0d6ab461",
    "source_number": 84,
    "authored_distractors": false
  },
  {
    "id": "47fe87dd-f796-5965-91d2-e39de1713d57",
    "external_key": "SAT_MATH:3409707e",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "EASY",
    "prompt": "$$x + y = 125$$\n$$x + y + y = 155$$\n\nThe solution to the given system of equations is $(x, y)$. What is the value of $y$?",
    "options": [
      {
        "id": "98b61412-e287-3895-8793-829a2133e04e",
        "key": "A",
        "text": "20"
      },
      {
        "id": "dab2a392-2d1e-39bf-afa1-679e84a658bb",
        "key": "B",
        "text": "40"
      },
      {
        "id": "2e2003a9-616b-3a62-bcca-09f66e2a92d0",
        "key": "C",
        "text": "30"
      },
      {
        "id": "60e3dda9-671e-3023-8dc7-b4a8efa67270",
        "key": "D",
        "text": "60"
      }
    ],
    "correct_option_id": "2e2003a9-616b-3a62-bcca-09f66e2a92d0",
    "explanation": "The correct answer is 30. Substituting $x + y = 125$ directly into the second equation:\n$$125 + y = 155$$\nSubtracting 125 from both sides:\n$$y = 30$$",
    "source_id": "3409707e",
    "source_number": 85,
    "authored_distractors": true
  },
  {
    "id": "4fcfd296-1286-585b-965c-040183c7163a",
    "external_key": "SAT_MATH:520c8177",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "EASY",
    "prompt": "A veterinarian recommends that each day a certain rabbit should eat 25 calories per pound of the rabbit’s weight, plus an additional 11 calories. Which equation represents this situation, where $c$ is the total number of calories the veterinarian recommends the rabbit should eat each day if the rabbit’s weight is $x$ pounds?",
    "options": [
      {
        "id": "4b949abd-6339-3850-986f-bf0965f11c6d",
        "key": "A",
        "text": "$c = 25x$"
      },
      {
        "id": "28f869c8-ae1f-3c81-904a-9723ab2a5648",
        "key": "B",
        "text": "$c = 36x$"
      },
      {
        "id": "0ce111df-f0af-3f46-9141-152726dd7710",
        "key": "C",
        "text": "$c = 11x + 25$"
      },
      {
        "id": "63b96859-a953-382c-9249-3ee3f34b6d83",
        "key": "D",
        "text": "$c = 25x + 11$"
      }
    ],
    "correct_option_id": "63b96859-a953-382c-9249-3ee3f34b6d83",
    "explanation": "Choice D is correct. Since the rabbit needs 25 calories for each of its $x$ pounds, the weight-based calories are $25x$. Adding the additional 11 calories yields the total daily recommended calories:\n$$c = 25x + 11$$",
    "source_id": "520c8177",
    "source_number": 86,
    "authored_distractors": false
  },
  {
    "id": "1b536a0b-1258-55e2-8a0b-69cf69a9352f",
    "external_key": "SAT_MATH:88e13c8c",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_FUNCTIONS",
    "topic_name": "Algebra / Linear functions",
    "difficulty": "EASY",
    "prompt": "The total cost $f(x)$, in dollars, to lease a car for 36 months from a particular car dealership is given by $f(x) = 36x + 1{,}000$, where $x$ is the monthly payment, in dollars. What is the total cost to lease a car when the monthly payment is $\\$400$?",
    "options": [
      {
        "id": "11faee4d-1c15-340e-854f-61ffb0609d79",
        "key": "A",
        "text": "$\\$13{,}400$"
      },
      {
        "id": "cffb77d7-9824-3efd-aede-11dd29cfe4f0",
        "key": "B",
        "text": "$\\$13{,}000$"
      },
      {
        "id": "0599faf4-5044-3e23-babe-f9c956d9f62e",
        "key": "C",
        "text": "$\\$15{,}400$"
      },
      {
        "id": "5bac4558-341a-3137-a48b-f39c2acac1dc",
        "key": "D",
        "text": "$\\$37{,}400$"
      }
    ],
    "correct_option_id": "0599faf4-5044-3e23-babe-f9c956d9f62e",
    "explanation": "Choice C is correct. Substituting $x = 400$ into the total cost function:\n$$f(400) = 36(400) + 1{,}000 = 14{,}400 + 1{,}000 = 15{,}400$$\nThus, the total cost to lease the car is $\\$15{,}400$.",
    "source_id": "88e13c8c",
    "source_number": 87,
    "authored_distractors": false
  },
  {
    "id": "8f79ec93-610c-5343-99a1-bcd794c7d1be",
    "external_key": "SAT_MATH:744ee7d7",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_INEQUALITIES",
    "topic_name": "Algebra / Linear inequalities in one or two variables",
    "difficulty": "EASY",
    "prompt": "The shaded region shown in the graph in the $xy$-plane has a solid horizontal boundary line passing through $(0, 36)$ and $(-15, 36)$, with shading covering all points on and above this line. The shaded region represents all the solutions to which inequality?",
    "options": [
      {
        "id": "61a5bb4c-8e52-34b6-a8fe-117e2892b22f",
        "key": "A",
        "text": "$x \\le 36$"
      },
      {
        "id": "f08e7840-c605-3fa8-b5e6-6bf8fbece80c",
        "key": "B",
        "text": "$x \\ge 36$"
      },
      {
        "id": "d4403949-7077-3a7f-bfc1-94eae47da5b7",
        "key": "C",
        "text": "$y \\le 36$"
      },
      {
        "id": "c599a43c-4929-399b-b4af-31647fc9a028",
        "key": "D",
        "text": "$y \\ge 36$"
      }
    ],
    "correct_option_id": "c599a43c-4929-399b-b4af-31647fc9a028",
    "explanation": "Choice D is correct. A horizontal line in the $xy$-plane has the equation $y = b$. Since the boundary line passes through $(0, 36)$, its equation is $y = 36$. The shaded region includes all points with $y$-coordinates greater than or equal to 36, which is represented by the inequality $y \\ge 36$.",
    "source_id": "744ee7d7",
    "source_number": 88,
    "authored_distractors": false
  },
  {
    "id": "e81c0fd9-e99a-5441-8f19-e5e73c489a8c",
    "external_key": "SAT_MATH:0adbe034",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_ONE_VARIABLE",
    "topic_name": "Algebra / Linear equations in one variable",
    "difficulty": "EASY",
    "prompt": "If $4x - 28 = -24$, what is the value of $x - 7$?",
    "options": [
      {
        "id": "18c5dc5d-1ba2-3d38-a7ee-391189b3dcda",
        "key": "A",
        "text": "$-24$"
      },
      {
        "id": "af6ccae2-7108-31dc-b655-2efffd502b47",
        "key": "B",
        "text": "$-22$"
      },
      {
        "id": "55c0489d-54fd-37d3-86d3-a4555f7edad8",
        "key": "C",
        "text": "$-6$"
      },
      {
        "id": "f87a56f5-8bf9-345e-8001-05623836cc8d",
        "key": "D",
        "text": "$-1$"
      }
    ],
    "correct_option_id": "55c0489d-54fd-37d3-86d3-a4555f7edad8",
    "explanation": "Choice C is correct. Notice that the expression $x - 7$ is obtained by dividing $4x - 28$ by 4:\n$$\\frac{4x - 28}{4} = \\frac{-24}{4} \\implies x - 7 = -6$$",
    "source_id": "0adbe034",
    "source_number": 89,
    "authored_distractors": false
  },
  {
    "id": "67360d33-4abc-57e8-ba4f-9551934d609c",
    "external_key": "SAT_MATH:b86123af",
    "discipline_code": "SAT_MATH",
    "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
    "topic_name": "Algebra / Systems of two linear equations in two variables",
    "difficulty": "EASY",
    "prompt": "Hiro and Sofia purchased shirts and pants from a store. The price of each shirt purchased was the same and the price of each pair of pants purchased was the same. Hiro purchased 4 shirts and 2 pairs of pants for $\\$86$, and Sofia purchased 3 shirts and 5 pairs of pants for $\\$166$. Which of the following systems of linear equations represents the situation, if $x$ represents the price, in dollars, of each shirt and $y$ represents the price, in dollars, of each pair of pants?",
    "options": [
      {
        "id": "4f808cd6-3b20-3b44-b63f-60a64acd8d8c",
        "key": "A",
        "text": "$\\begin{cases} 4x + 2y = 86 \\\\ 3x + 5y = 166 \\end{cases}$"
      },
      {
        "id": "aa9d3a40-f7af-339e-9dc3-eb4cd748b394",
        "key": "B",
        "text": "$\\begin{cases} 4x + 3y = 86 \\\\ 2x + 5y = 166 \\end{cases}$"
      },
      {
        "id": "1e58ec13-7f53-3dfc-9372-76747b9ac8c6",
        "key": "C",
        "text": "$\\begin{cases} 4x + 2y = 166 \\\\ 3x + 5y = 86 \\end{cases}$"
      },
      {
        "id": "759a82cb-6175-3a90-94bd-d79927fb742f",
        "key": "D",
        "text": "$\\begin{cases} 4x + 3y = 166 \\\\ 2x + 5y = 86 \\end{cases}$"
      }
    ],
    "correct_option_id": "4f808cd6-3b20-3b44-b63f-60a64acd8d8c",
    "explanation": "Choice A is correct.\n- Hiro bought 4 shirts at $x$ dollars each and 2 pairs of pants at $y$ dollars each for a total of $\\$86$: $4x + 2y = 86$.\n- Sofia bought 3 shirts at $x$ dollars each and 5 pairs of pants at $y$ dollars each for a total of $\\$166$: $3x + 5y = 166$.\nThis gives the system in Choice A.",
    "source_id": "b86123af",
    "source_number": 90,
    "authored_distractors": false
  },
  {
    "id": "e71dc91e-337c-5aa7-a1e8-ebffb667ab6c",
    "external_key": "SAT_MATH:1ee962ec",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "EASY",
    "prompt": "Scientists recorded data about the ocean water levels at a certain location over a period of 6 hours. The graph shown models the data, where $y = 0$ represents sea level. The graph is a parabola opening upward with vertex at $(3, -12)$ that intersects the $x$-axis at $(0, 0)$ and $(6, 0)$. Which table gives values of $x$ and their corresponding values of $y$ based on the model?",
    "options": [
      {
        "id": "dfffc2ae-82f4-33f3-95bf-36712a071c0f",
        "key": "A",
        "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | $-12$ |\n  | 0 | 3 |\n  | 3 | 6 |"
      },
      {
        "id": "5ff10220-a960-32c9-870b-f1e73d72d8fb",
        "key": "B",
        "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | 0 |\n  | 3 | 12 |\n  | 0 | $-6$ |"
      },
      {
        "id": "3fdfa472-20b6-3c97-9c89-cc5bb05b861f",
        "key": "C",
        "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | 0 |\n  | 3 | $-12$ |\n  | 6 | 0 |"
      },
      {
        "id": "16e043e0-abad-3d5a-8561-d27af49e19e4",
        "key": "D",
        "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | 0 |\n  | 12 | 3 |\n  | $-6$ | 0 |"
      }
    ],
    "correct_option_id": "3fdfa472-20b6-3c97-9c89-cc5bb05b861f",
    "explanation": "Choice C is correct. The graph represents points $(x, y)$ where $x$ is elapsed time in hours and $y$ is ocean water level in feet. The graph starts at $(0, 0)$, reaches its minimum at the vertex $(3, -12)$, and returns to sea level at $(6, 0)$. These three points match the entries in table C.",
    "source_id": "1ee962ec",
    "source_number": 91,
    "authored_distractors": false
  },
  {
    "id": "e258ddf6-b312-5106-b680-8f7829c9bde8",
    "external_key": "SAT_MATH:c6a26e14",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_EQUATIONS",
    "topic_name": "Advanced Math / Nonlinear equations in one variable and systems of equations in two variables",
    "difficulty": "EASY",
    "prompt": "$$|x + 45| = 48$$\n\nWhat is the positive solution to the given equation?",
    "options": [
      {
        "id": "8070b3ae-1eae-3578-a25d-9172de2c630d",
        "key": "A",
        "text": "3"
      },
      {
        "id": "c54ebcc6-d382-3cb8-8eb6-c0f0189a9ba4",
        "key": "B",
        "text": "48"
      },
      {
        "id": "225ea073-c9bf-3460-a2c9-2f6e76511f0a",
        "key": "C",
        "text": "93"
      },
      {
        "id": "d39fd9b3-4067-3442-a216-61b8d5796f20",
        "key": "D",
        "text": "96"
      }
    ],
    "correct_option_id": "8070b3ae-1eae-3578-a25d-9172de2c630d",
    "explanation": "Choice A is correct. An absolute value equation $|u| = c$ splits into two linear equations:\n1. $x + 45 = 48 \\implies x = 48 - 45 = 3$\n2. $x + 45 = -48 \\implies x = -48 - 45 = -93$\nThe problem asks for the positive solution, which is 3.",
    "source_id": "c6a26e14",
    "source_number": 92,
    "authored_distractors": false
  },
  {
    "id": "a58bf2b5-8e4b-56ec-8559-f4d1a642423b",
    "external_key": "SAT_MATH:07bcecac",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "EASY",
    "prompt": "The function $P$ gives the predicted population, in millions, of a certain country for the period from 1984 to 2018, where $t$ is the number of years after 1984:\n$$P(t) = 24.8(1.036)^t$$\nAccording to the model, what is the best interpretation of the statement “$P(8)$ is approximately equal to $32.91$”?",
    "options": [
      {
        "id": "b8ed6269-ac7c-38fa-83ce-4f389145793f",
        "key": "A",
        "text": "In 1984, the predicted population of this country was approximately 8 million."
      },
      {
        "id": "2f9289a5-e081-3fdd-aeea-e656a2f2482d",
        "key": "B",
        "text": "In 1984, the predicted population of this country was approximately 32.91 million."
      },
      {
        "id": "ad975659-a210-3018-a6a9-3b830308156c",
        "key": "C",
        "text": "8 years after 1984, the predicted population of this country was approximately 32.91 million."
      },
      {
        "id": "8c0f4341-8192-36d0-8482-2c04f99f9005",
        "key": "D",
        "text": "32.91 years after 1984, the predicted population of this country was approximately 8 million."
      }
    ],
    "correct_option_id": "ad975659-a210-3018-a6a9-3b830308156c",
    "explanation": "Choice C is correct. In this model, $t$ is the number of years after 1984 and $P(t)$ is the predicted population in millions. Therefore, $P(8) \\approx 32.91$ means that 8 years after 1984, the predicted population of this country was approximately 32.91 million.",
    "source_id": "07bcecac",
    "source_number": 93,
    "authored_distractors": false
  },
  {
    "id": "283653a5-6189-5bc8-bca6-9267329d468a",
    "external_key": "SAT_MATH:ad03127d",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_EQUATIONS",
    "topic_name": "Advanced Math / Nonlinear equations in one variable and systems of equations in two variables",
    "difficulty": "EASY",
    "prompt": "$$6r = 7s + t$$\n\nThe given equation relates the variables $r$, $s$, and $t$. Which equation correctly expresses $s$ in terms of $r$ and $t$?",
    "options": [
      {
        "id": "4f224184-427e-3eac-a2a2-a44841d8aef6",
        "key": "A",
        "text": "$s = 42r - t$"
      },
      {
        "id": "15998827-c19b-3b50-bcc6-bf1acf31ce34",
        "key": "B",
        "text": "$s = 7(6r - t)$"
      },
      {
        "id": "2bf66d30-0565-3e89-8f74-9bcfcecfcd93",
        "key": "C",
        "text": "$s = \\frac{6}{7}r - t$"
      },
      {
        "id": "1ff7534f-67e4-32a2-a12e-6b24b52db667",
        "key": "D",
        "text": "$s = \\frac{6r - t}{7}$"
      }
    ],
    "correct_option_id": "1ff7534f-67e4-32a2-a12e-6b24b52db667",
    "explanation": "Choice D is correct. Isolating $s$ in the given equation:\n$$6r = 7s + t$$\nSubtracting $t$ from both sides:\n$$6r - t = 7s$$\nDividing both sides by 7:\n$$s = \\frac{6r - t}{7}$$",
    "source_id": "ad03127d",
    "source_number": 94,
    "authored_distractors": false
  },
  {
    "id": "3caaacc6-8443-52e5-89f6-1792ae1a5745",
    "external_key": "SAT_MATH:788bfd56",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "EASY",
    "prompt": "The function $f$ is defined by $f(x) = 4 + \\sqrt{x}$. What is the value of $f(144)$?",
    "options": [
      {
        "id": "e033cbaa-fc6a-34c7-b562-d2e248ba4c2d",
        "key": "A",
        "text": "0"
      },
      {
        "id": "36460013-8ccc-33c9-af30-107d6b5c8234",
        "key": "B",
        "text": "16"
      },
      {
        "id": "33e66270-32b8-3157-9ae3-9213dd25631e",
        "key": "C",
        "text": "40"
      },
      {
        "id": "141679ec-8b6f-3673-90ff-72022a787fc3",
        "key": "D",
        "text": "76"
      }
    ],
    "correct_option_id": "36460013-8ccc-33c9-af30-107d6b5c8234",
    "explanation": "Choice B is correct. Evaluating $f(144)$:\n$$f(144) = 4 + \\sqrt{144}$$\nSince $\\sqrt{144} = 12$:\n$$f(144) = 4 + 12 = 16$$",
    "source_id": "788bfd56",
    "source_number": 95,
    "authored_distractors": false
  },
  {
    "id": "34dfce62-3398-5794-8eda-caf3548b9ef9",
    "external_key": "SAT_MATH:369b7bb7",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "EASY",
    "prompt": "The function $g$ is defined by $g(x) = \\sqrt{8x + 1}$. What is the value of $g(3)$?",
    "options": [
      {
        "id": "a3caa906-7e52-391a-bab8-8c748be2014b",
        "key": "A",
        "text": "$\\frac{5}{8}$"
      },
      {
        "id": "1876e9df-dd49-3f6b-8322-5b7dab70b9c9",
        "key": "B",
        "text": "$\\frac{25}{8}$"
      },
      {
        "id": "343d53c6-9961-3eb3-8511-b6e7609c4cc8",
        "key": "C",
        "text": "5"
      },
      {
        "id": "f1a746d3-8915-30d6-a307-03feee435ff0",
        "key": "D",
        "text": "25"
      }
    ],
    "correct_option_id": "343d53c6-9961-3eb3-8511-b6e7609c4cc8",
    "explanation": "Choice C is correct. Substituting $x = 3$ into the function:\n$$g(3) = \\sqrt{8(3) + 1} = \\sqrt{24 + 1} = \\sqrt{25} = 5$$",
    "source_id": "369b7bb7",
    "source_number": 96,
    "authored_distractors": false
  },
  {
    "id": "2cb8dae3-251d-5b58-a058-47741811ee92",
    "external_key": "SAT_MATH:5ba187d4",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "EASY",
    "prompt": "Which expression is equivalent to $100x^2 + 2{,}600$?",
    "options": [
      {
        "id": "b33b66b1-f9ed-3074-99a6-809e3856d7d4",
        "key": "A",
        "text": "$100(26x^2)$"
      },
      {
        "id": "3c2b7d8e-7b92-3a02-ac66-e50e5e1cb195",
        "key": "B",
        "text": "$100(x^2 + 26)$"
      },
      {
        "id": "75127f5d-6836-3823-8653-3ce445648e1c",
        "key": "C",
        "text": "$2{,}600(100x^2)$"
      },
      {
        "id": "f6050e5a-579b-3cf4-80c9-dd80bc25130e",
        "key": "D",
        "text": "$2{,}600(100x^2 + 1)$"
      }
    ],
    "correct_option_id": "3c2b7d8e-7b92-3a02-ac66-e50e5e1cb195",
    "explanation": "Choice B is correct. Both terms share a common factor of 100:\n$$100x^2 + 2{,}600 = 100(x^2) + 100(26) = 100(x^2 + 26)$$",
    "source_id": "5ba187d4",
    "source_number": 97,
    "authored_distractors": false
  },
  {
    "id": "885d6177-0135-59dd-953c-db1cc3d377b4",
    "external_key": "SAT_MATH:3cf2698e",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
    "topic_name": "Advanced Math / Nonlinear functions",
    "difficulty": "EASY",
    "prompt": "The number of cells of a certain bacteria doubles every 25 minutes during its growth period when placed in a medium of milk in a controlled laboratory environment. If a sample of 830 cells of this bacteria is placed in milk in a controlled laboratory environment, which function best represents the number of cells of the bacteria $x$ minutes after the growth period begins, where $x$ is less than the number of minutes in the growth period?",
    "options": [
      {
        "id": "adbfb43d-b17f-39f4-9662-a146ef47b640",
        "key": "A",
        "text": "$f(x) = 830(\\frac{1}{2})^{\\frac{x}{25}}$"
      },
      {
        "id": "09b45ac8-6b01-3728-a457-889c093f3c5c",
        "key": "B",
        "text": "$f(x) = 830(2)^{\\frac{x}{25}}$"
      },
      {
        "id": "9e735f48-5eca-3dbb-97fe-0af170cdedb3",
        "key": "C",
        "text": "$f(x) = 830(\\frac{1}{3})^{\\frac{x}{25}}$"
      },
      {
        "id": "7d4932d0-ba76-3135-8f74-b33f749a35bf",
        "key": "D",
        "text": "$f(x) = 830(3)^{\\frac{x}{25}}$"
      }
    ],
    "correct_option_id": "09b45ac8-6b01-3728-a457-889c093f3c5c",
    "explanation": "Choice B is correct. An exponential growth model with doubling time $d$ and initial population $P_0$ is given by $f(x) = P_0(2)^{\\frac{x}{d}}$.\nGiven initial population $P_0 = 830$ and doubling time $d = 25\\text{ minutes}$:\n$$f(x) = 830(2)^{\\frac{x}{25}}$$",
    "source_id": "3cf2698e",
    "source_number": 98,
    "authored_distractors": false
  },
  {
    "id": "ce8ff12a-5d4f-5125-9df2-5a4d95b2c7cd",
    "external_key": "SAT_MATH:253985c2",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "EASY",
    "prompt": "Which expression is equivalent to $6x + 5x + 4y$?",
    "options": [
      {
        "id": "98ad57b1-b014-3cbe-a033-f113301a3eb2",
        "key": "A",
        "text": "$15x$"
      },
      {
        "id": "820aa240-d0dc-33d1-a43b-d3a162c9cdfc",
        "key": "B",
        "text": "$15y$"
      },
      {
        "id": "cc67e9d1-2531-3c4a-b7a0-77b16137c1f0",
        "key": "C",
        "text": "$11x + 4y$"
      },
      {
        "id": "d34f43fb-0bec-3d50-80ca-bbae0e1a4c7b",
        "key": "D",
        "text": "$30x + 4y$"
      }
    ],
    "correct_option_id": "cc67e9d1-2531-3c4a-b7a0-77b16137c1f0",
    "explanation": "Choice C is correct. The terms $6x$ and $5x$ are like terms:\n$$6x + 5x = (6 + 5)x = 11x$$\nAdding $4y$ yields:\n$$11x + 4y$$",
    "source_id": "253985c2",
    "source_number": 99,
    "authored_distractors": false
  },
  {
    "id": "4f74f91b-5a9b-52f4-9fde-73f478309219",
    "external_key": "SAT_MATH:4ac59df6",
    "discipline_code": "SAT_MATH",
    "topic_code": "ADVANCED_EQUIVALENT_EXPRESSIONS",
    "topic_name": "Advanced Math / Equivalent expressions",
    "difficulty": "EASY",
    "prompt": "Which expression is equivalent to $(8yz)(y)(7z)$?",
    "options": [
      {
        "id": "bd0e7855-4efd-3a91-839d-8e796cf0c76d",
        "key": "A",
        "text": "$56y^2z^2$"
      },
      {
        "id": "62f328a8-729f-3cc3-ae6a-ebe761a50f6c",
        "key": "B",
        "text": "$56y^2z$"
      },
      {
        "id": "5d6e8a5b-37e6-3615-a2dc-c0afcbbca6a8",
        "key": "C",
        "text": "$56yz$"
      },
      {
        "id": "c1d09cc7-01a0-3b9a-b535-c6f0555a08dd",
        "key": "D",
        "text": "$16yz$"
      }
    ],
    "correct_option_id": "bd0e7855-4efd-3a91-839d-8e796cf0c76d",
    "explanation": "Choice A is correct. Applying the commutative and associative properties of multiplication:\n$$(8yz)(y)(7z) = (8 \\times 7) \\times (y \\times y) \\times (z \\times z) = 56y^2z^2$$",
    "source_id": "4ac59df6",
    "source_number": 100,
    "authored_distractors": false
  },
  {
    "id": "94389f43-601a-50b5-b692-d8a1342d3f11",
    "external_key": "SAT_MATH:59cb654c",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "EASY",
    "prompt": "The area of a square is 64 square inches. What is the side length, in inches, of this square?",
    "options": [
      {
        "id": "a150a637-a0d9-3441-b85f-5ab8845efac3",
        "key": "A",
        "text": "8"
      },
      {
        "id": "33ec0911-0b7d-3644-b25b-471b50db979c",
        "key": "B",
        "text": "16"
      },
      {
        "id": "3d8b2357-dbfe-38e3-8410-a31bece874bf",
        "key": "C",
        "text": "64"
      },
      {
        "id": "4eb13d77-7852-354c-ab3d-28c66604888f",
        "key": "D",
        "text": "128"
      }
    ],
    "correct_option_id": "a150a637-a0d9-3441-b85f-5ab8845efac3",
    "explanation": "Choice A is correct. The area $A$ of a square with side length $s$ is given by $A = s^2$. Given $A = 64$:\n$$64 = s^2 \\implies s = \\sqrt{64} = 8\\text{ inches}$$",
    "source_id": "59cb654c",
    "source_number": 101,
    "authored_distractors": false
  },
  {
    "id": "c901daa6-f209-5b9b-855e-e581eb243261",
    "external_key": "SAT_MATH:2b41a4c4",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "EASY",
    "prompt": "A right rectangular prism has a length of 11 meters, a width of 8 meters, and a height of 10 meters. What is the volume, in cubic meters, of the prism?",
    "options": [
      {
        "id": "1e6a3f02-7017-3f11-8731-13ba6b426f55",
        "key": "A",
        "text": "880"
      },
      {
        "id": "092e4c4e-16f9-37e6-8519-39a379cef96d",
        "key": "B",
        "text": "88"
      },
      {
        "id": "b9448af5-2842-314a-859b-82331b1883ec",
        "key": "C",
        "text": "440"
      },
      {
        "id": "aac8c93a-2763-31cf-9abe-265aa5b02ac1",
        "key": "D",
        "text": "1760"
      }
    ],
    "correct_option_id": "1e6a3f02-7017-3f11-8731-13ba6b426f55",
    "explanation": "The correct answer is 880. The volume $V$ of a right rectangular prism is given by the formula $V = \\ell w h$. Substituting $\\ell = 11$, $w = 8$, and $h = 10$:\n$$V = (11)(8)(10) = 880\\text{ cubic meters}$$",
    "source_id": "2b41a4c4",
    "source_number": 102,
    "authored_distractors": true
  },
  {
    "id": "318e612e-da81-5e29-becf-8d08f57b4902",
    "external_key": "SAT_MATH:cbe8ca31",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "EASY",
    "prompt": "In $\\triangle XYZ$, the measure of $\\angle X$ is $24^\\circ$ and the measure of $\\angle Y$ is $98^\\circ$. What is the measure of $\\angle Z$?",
    "options": [
      {
        "id": "b1750843-48f1-3dd7-bba9-01118b886ba6",
        "key": "A",
        "text": "$58^\\circ$"
      },
      {
        "id": "748ba04e-b51a-334b-b11f-b36063f913af",
        "key": "B",
        "text": "$74^\\circ$"
      },
      {
        "id": "f67cbff1-565d-31da-9126-b2717647f25c",
        "key": "C",
        "text": "$122^\\circ$"
      },
      {
        "id": "b001fb6a-0320-37c4-9f87-92bc3f6af0b6",
        "key": "D",
        "text": "$212^\\circ$"
      }
    ],
    "correct_option_id": "b1750843-48f1-3dd7-bba9-01118b886ba6",
    "explanation": "Choice A is correct. The sum of the measures of the interior angles of a triangle is $180^\\circ$:\n$$m\\angle X + m\\angle Y + m\\angle Z = 180^\\circ$$\n$$24^\\circ + 98^\\circ + m\\angle Z = 180^\\circ \\implies 122^\\circ + m\\angle Z = 180^\\circ \\implies m\\angle Z = 58^\\circ$$",
    "source_id": "cbe8ca31",
    "source_number": 103,
    "authored_distractors": false
  },
  {
    "id": "55e54495-b4d5-573a-8909-078ca20d818c",
    "external_key": "SAT_MATH:124bc42b",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "EASY",
    "prompt": "Rectangle $ABCD$ shown has a length of 7 units and a width of 2 units. What is the area, in square units, of rectangle $ABCD$?",
    "options": [
      {
        "id": "4cc9b820-b851-39a1-9f94-03a2d62ca6ac",
        "key": "A",
        "text": "5"
      },
      {
        "id": "93f9a884-a907-3ca0-956f-b7f3e99f88c0",
        "key": "B",
        "text": "9"
      },
      {
        "id": "009e051c-f911-3825-b5d0-bb625e884454",
        "key": "C",
        "text": "14"
      },
      {
        "id": "2f74fed8-5cf1-31fa-95da-26b7952aaed6",
        "key": "D",
        "text": "28"
      }
    ],
    "correct_option_id": "009e051c-f911-3825-b5d0-bb625e884454",
    "explanation": "Choice C is correct. The area $A$ of a rectangle is the product of its length and width:\n$$A = \\ell w = 7 \\times 2 = 14\\text{ square units}$$",
    "source_id": "124bc42b",
    "source_number": 104,
    "authored_distractors": false
  },
  {
    "id": "3b5f8998-b856-5151-8b58-8062c29667c9",
    "external_key": "SAT_MATH:c24e1bda",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
    "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
    "difficulty": "EASY",
    "prompt": "In the figure, line $m$ is parallel to line $n$. Transversal $t$ intersects line $m$ and line $n$, forming corresponding angles with measures $134^\\circ$ and $w^\\circ$. What is the value of $w$?",
    "options": [
      {
        "id": "dee6c169-cae4-3fd8-92f4-09b5243d7eef",
        "key": "A",
        "text": "13"
      },
      {
        "id": "5cfc4ea3-f1d4-34be-811d-df2df66110ce",
        "key": "B",
        "text": "34"
      },
      {
        "id": "b2d859b9-8f8a-3651-918f-86f2aa832ab0",
        "key": "C",
        "text": "66"
      },
      {
        "id": "118cd011-2d56-3cca-beb8-e38bc8f0d960",
        "key": "D",
        "text": "134"
      }
    ],
    "correct_option_id": "118cd011-2d56-3cca-beb8-e38bc8f0d960",
    "explanation": "Choice D is correct. When two parallel lines are cut by a transversal, corresponding angles are congruent and have equal measures. Since the angle of $134^\\circ$ and the angle of $w^\\circ$ are corresponding angles:\n$$w = 134$$",
    "source_id": "c24e1bda",
    "source_number": 105,
    "authored_distractors": false
  },
  {
    "id": "fd54386d-a831-5119-8ceb-f15b4dad2721",
    "external_key": "SAT_MATH:e6f2ace7",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "EASY",
    "prompt": "The lengths of the legs of a right triangle are 3 and 7. Which of the following is closest to the length of the triangle’s hypotenuse?",
    "options": [
      {
        "id": "fe027c0c-d3e2-3c7c-8480-e86e7c4faed8",
        "key": "A",
        "text": "3.2"
      },
      {
        "id": "d01be096-22d6-347b-a850-b3bbf7270d26",
        "key": "B",
        "text": "5"
      },
      {
        "id": "b3053de7-a828-36ad-93e6-e62e53d75f69",
        "key": "C",
        "text": "7.6"
      },
      {
        "id": "b6eef288-e7c8-3eb3-b4dc-61444cef3dc0",
        "key": "D",
        "text": "20"
      }
    ],
    "correct_option_id": "b3053de7-a828-36ad-93e6-e62e53d75f69",
    "explanation": "Choice C is correct. According to the Pythagorean theorem, for a right triangle with legs $a$ and $b$ and hypotenuse $c$:\n$$a^2 + b^2 = c^2$$\nSubstituting $a = 3$ and $b = 7$:\n$$3^2 + 7^2 = c^2 \\implies 9 + 49 = c^2 \\implies c^2 = 58 \\implies c = \\sqrt{58} \\approx 7.615$$\nAmong the choices, 7.6 is closest to the length of the hypotenuse.",
    "source_id": "e6f2ace7",
    "source_number": 106,
    "authored_distractors": false
  },
  {
    "id": "5a5fc29c-4f58-5671-9a6a-d7e3084c51e1",
    "external_key": "SAT_MATH:b0c5ece5",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
    "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
    "difficulty": "EASY",
    "prompt": "A right triangle has legs with lengths 4 and $b$ and a hypotenuse of length 19. Which equation shows the relationship between the side lengths of the given triangle?",
    "options": [
      {
        "id": "18c06f87-e2d7-3286-b8bc-804d75da0b8e",
        "key": "A",
        "text": "$4b = 19$"
      },
      {
        "id": "5643e2c2-5407-34e3-9fb3-9e033c8672d0",
        "key": "B",
        "text": "$4 + b = 19$"
      },
      {
        "id": "0aefafe2-0b70-3723-9b1a-a175ed7dda88",
        "key": "C",
        "text": "$4^2 + b^2 = 19^2$"
      },
      {
        "id": "283be9e8-8eed-334a-b855-7031900ec08a",
        "key": "D",
        "text": "$4^2 - b^2 = 19^2$"
      }
    ],
    "correct_option_id": "0aefafe2-0b70-3723-9b1a-a175ed7dda88",
    "explanation": "Choice C is correct. By the Pythagorean theorem, the sum of the squares of the lengths of the two legs equals the square of the length of the hypotenuse:\n$$a^2 + b^2 = c^2 \\implies 4^2 + b^2 = 19^2$$",
    "source_id": "b0c5ece5",
    "source_number": 107,
    "authored_distractors": false
  },
  {
    "id": "2a22951e-5e30-5b58-80a7-f6d89eda1aa2",
    "external_key": "SAT_MATH:2a549721",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "EASY",
    "prompt": "Rectangle $ABCD$ has an area of 280 square centimeters. The length of the rectangle is 10 centimeters. What is the width, in centimeters, of the rectangle?",
    "options": [
      {
        "id": "684593ad-cc79-3891-a142-780d9eb8583f",
        "key": "A",
        "text": "10"
      },
      {
        "id": "81a40254-c732-3e6c-ac63-1f309a1f375e",
        "key": "B",
        "text": "28"
      },
      {
        "id": "d07eeb2b-1c00-36f3-8c39-1075bac41ebe",
        "key": "C",
        "text": "76"
      },
      {
        "id": "3197671c-fbd6-3d6c-b5c6-dbc83b7ece27",
        "key": "D",
        "text": "140"
      }
    ],
    "correct_option_id": "81a40254-c732-3e6c-ac63-1f309a1f375e",
    "explanation": "Choice B is correct. The area $A$ of a rectangle is given by $A = \\ell w$. Given $A = 280$ and $\\ell = 10$:\n$$280 = 10w \\implies w = \\frac{280}{10} = 28\\text{ centimeters}$$",
    "source_id": "2a549721",
    "source_number": 108,
    "authored_distractors": false
  },
  {
    "id": "43e55741-9d85-5f2e-9f94-fa57c589c5cb",
    "external_key": "SAT_MATH:d0b6d927",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "EASY",
    "prompt": "A rectangle has an area of 63 square meters and a length of 9 meters. What is the width, in meters, of the rectangle?",
    "options": [
      {
        "id": "ff92eeb2-033d-3fac-8889-e71150e6e897",
        "key": "A",
        "text": "7"
      },
      {
        "id": "249db53a-48c9-3efa-9500-f86873c55265",
        "key": "B",
        "text": "54"
      },
      {
        "id": "dae6c67e-9768-3a85-a4c4-6b12eefb5628",
        "key": "C",
        "text": "81"
      },
      {
        "id": "117d5b67-e6f2-3749-98d0-f5cdc0f41afb",
        "key": "D",
        "text": "567"
      }
    ],
    "correct_option_id": "ff92eeb2-033d-3fac-8889-e71150e6e897",
    "explanation": "Choice A is correct. The area $A$ of a rectangle is given by $A = \\ell w$. Given $A = 63$ and $\\ell = 9$:\n$$63 = 9w \\implies w = \\frac{63}{9} = 7\\text{ meters}$$",
    "source_id": "d0b6d927",
    "source_number": 109,
    "authored_distractors": false
  },
  {
    "id": "3b13d87a-8f55-532c-9978-8467d851491a",
    "external_key": "SAT_MATH:32f99025",
    "discipline_code": "SAT_MATH",
    "topic_code": "GEOMETRY_AREA_VOLUME",
    "topic_name": "Geometry and Trigonometry / Area and volume",
    "difficulty": "EASY",
    "prompt": "The length of the base of a triangle is 8 inches, and the height of the triangle is 12 inches. What is the area, in square inches, of the triangle?",
    "options": [
      {
        "id": "25e8822a-ebb7-3efa-a2e2-1e82ceadfbd7",
        "key": "A",
        "text": "20"
      },
      {
        "id": "a38e73e8-39aa-3a8e-8e87-9ce18b1a04e1",
        "key": "B",
        "text": "48"
      },
      {
        "id": "8e8267d0-3a95-3531-bbb2-23b1cb6aad39",
        "key": "C",
        "text": "60"
      },
      {
        "id": "6087fe6c-aa0c-3b9c-a971-1dd49f553b6d",
        "key": "D",
        "text": "96"
      }
    ],
    "correct_option_id": "a38e73e8-39aa-3a8e-8e87-9ce18b1a04e1",
    "explanation": "Choice B is correct. The area $A$ of a triangle is given by the formula $A = \\frac{1}{2}bh$:\n$$A = \\frac{1}{2}(8)(12) = 4 \\times 12 = 48\\text{ square inches}$$",
    "source_id": "32f99025",
    "source_number": 110,
    "authored_distractors": false
  },
  {
    "id": "41c3e5aa-f341-501b-9075-bfa5145f0b17",
    "external_key": "SAT_MATH:312ba47c",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_RATIOS_RATES_UNITS",
    "topic_name": "Problem-Solving and Data Analysis / Ratios, rates, proportional relationships, and units",
    "difficulty": "EASY",
    "prompt": "In a box of pens, the ratio of black pens to red pens is 8 to 1. There are 40 black pens in the box. How many red pens are in the box?",
    "options": [
      {
        "id": "fbe962e0-e5e8-37fa-ab39-d091e466c0d7",
        "key": "A",
        "text": "5"
      },
      {
        "id": "82f1e0f9-7041-313a-bf93-6c44af917284",
        "key": "B",
        "text": "8"
      },
      {
        "id": "01a02b81-8e48-3115-ba28-94c22123745b",
        "key": "C",
        "text": "40"
      },
      {
        "id": "d74b4d9e-b9ba-375a-8eef-82c1dee9242b",
        "key": "D",
        "text": "320"
      }
    ],
    "correct_option_id": "fbe962e0-e5e8-37fa-ab39-d091e466c0d7",
    "explanation": "Choice A is correct. The ratio of black pens to red pens is $\\frac{8}{1}$. Setting up a proportion with 40 black pens:\n$$\\frac{8}{1} = \\frac{40}{r} \\implies 8r = 40 \\implies r = \\frac{40}{8} = 5$$",
    "source_id": "312ba47c",
    "source_number": 111,
    "authored_distractors": false
  },
  {
    "id": "04204a4c-b394-575d-abf2-d34649d7fb4d",
    "external_key": "SAT_MATH:90eed2e5",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_STATISTICAL_INFERENCE",
    "topic_name": "Problem-Solving and Data Analysis / Inference from sample statistics and margin of error",
    "difficulty": "EASY",
    "prompt": "A city has 50 city council members. A reporter polled a random sample of 20 city council members and found that 6 of those polled supported a specific bill. Based on the sample, which of the following is the best estimate of the number of city council members in the city who support the bill?",
    "options": [
      {
        "id": "e2578e83-3bca-3975-804f-7d25514d9ada",
        "key": "A",
        "text": "6"
      },
      {
        "id": "9d7ab41e-08f7-3b42-8c66-7763fd567abc",
        "key": "B",
        "text": "9"
      },
      {
        "id": "332c3aa4-93b7-383e-8f9d-d6db31105fa7",
        "key": "C",
        "text": "15"
      },
      {
        "id": "e1974ffa-abe9-3eb1-80a5-de2c7a9b8a11",
        "key": "D",
        "text": "30"
      }
    ],
    "correct_option_id": "332c3aa4-93b7-383e-8f9d-d6db31105fa7",
    "explanation": "Choice C is correct. The proportion of the polled sample who support the bill is:\n$$\\frac{6}{20} = 0.30 = 30\\%$$\nMultiplying this proportion by the total number of city council members gives the best estimate:\n$$50 \\times 0.30 = 15$$",
    "source_id": "90eed2e5",
    "source_number": 112,
    "authored_distractors": false
  },
  {
    "id": "bd58a960-f48b-510b-8689-1d2bce8d6668",
    "external_key": "SAT_MATH:15617f62",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_RATIOS_RATES_UNITS",
    "topic_name": "Problem-Solving and Data Analysis / Ratios, rates, proportional relationships, and units",
    "difficulty": "EASY",
    "prompt": "The population density of Worthington is 290 people per square mile. Worthington has a population of 92,800 people. What is the area, in square miles, of Worthington?",
    "options": [
      {
        "id": "83da43e1-05ab-3f91-b155-90a66d9b2253",
        "key": "A",
        "text": "102,400"
      },
      {
        "id": "d1805d23-81df-3e61-9136-def774d0b975",
        "key": "B",
        "text": "93,090"
      },
      {
        "id": "e8b07935-a943-3cdf-be66-6e827832d154",
        "key": "C",
        "text": "320"
      },
      {
        "id": "bf421d34-15c7-3bb2-89b9-b9407299be4f",
        "key": "D",
        "text": "32"
      }
    ],
    "correct_option_id": "e8b07935-a943-3cdf-be66-6e827832d154",
    "explanation": "Choice C is correct. Population density is defined as population divided by area:\n$$\\text{Density} = \\frac{\\text{Population}}{\\text{Area}} \\implies \\text{Area} = \\frac{\\text{Population}}{\\text{Density}}$$\nSubstituting the given values:\n$$\\text{Area} = \\frac{92{,}800}{290} = 320\\text{ square miles}$$",
    "source_id": "15617f62",
    "source_number": 113,
    "authored_distractors": false
  },
  {
    "id": "3aefd13f-d071-5c08-a28a-d540c6a87c2d",
    "external_key": "SAT_MATH:8736334b",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "EASY",
    "prompt": "Data set A: $72, 73, 73, 76, 76$\nData set B: $61, 64, 74, 85, x$\n\nData set A and data set B each contain 5 numbers. If the mean of data set A is equal to the mean of data set B, what is the value of $x$?",
    "options": [
      {
        "id": "3d09dd99-0d49-364a-80a2-76ecd10a4a96",
        "key": "A",
        "text": "77"
      },
      {
        "id": "3812462c-fb14-36d7-823d-7433114eeaa5",
        "key": "B",
        "text": "85"
      },
      {
        "id": "1a4aff6b-1688-3ee5-80de-748ade92a705",
        "key": "C",
        "text": "86"
      },
      {
        "id": "7616fb13-d45f-378d-8d5b-09b1cbf2f96a",
        "key": "D",
        "text": "95"
      }
    ],
    "correct_option_id": "1a4aff6b-1688-3ee5-80de-748ade92a705",
    "explanation": "Choice C is correct. The sum of the numbers in data set A is:\n$$72 + 73 + 73 + 76 + 76 = 370$$\nThe mean of data set A is $\\frac{370}{5} = 74$.\nSince both data sets have 5 numbers and equal means, their sums must also be equal:\n$$61 + 64 + 74 + 85 + x = 370$$\n$$284 + x = 370 \\implies x = 370 - 284 = 86$$",
    "source_id": "8736334b",
    "source_number": 114,
    "authored_distractors": false
  },
  {
    "id": "6d365a2e-f5ab-53be-8371-85ea5c49b904",
    "external_key": "SAT_MATH:be35c117",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_RATIOS_RATES_UNITS",
    "topic_name": "Problem-Solving and Data Analysis / Ratios, rates, proportional relationships, and units",
    "difficulty": "EASY",
    "prompt": "A wind turbine completes 900 revolutions in 50 minutes. At this rate, how many revolutions per minute does this turbine complete?",
    "options": [
      {
        "id": "9f14e1fd-c40a-34d3-9138-370823452e41",
        "key": "A",
        "text": "18"
      },
      {
        "id": "23d83659-9f3e-3581-ae7a-73d0f0a82ad5",
        "key": "B",
        "text": "850"
      },
      {
        "id": "dee6a00b-1987-32ab-b781-98f834651a1d",
        "key": "C",
        "text": "950"
      },
      {
        "id": "8f64e72d-72f1-323f-b85c-211c34064ae8",
        "key": "D",
        "text": "1,400"
      }
    ],
    "correct_option_id": "9f14e1fd-c40a-34d3-9138-370823452e41",
    "explanation": "Choice A is correct. The rate in revolutions per minute is:\n$$\\frac{900\\text{ revolutions}}{50\\text{ minutes}} = 18\\text{ revolutions per minute}$$",
    "source_id": "be35c117",
    "source_number": 115,
    "authored_distractors": false
  },
  {
    "id": "960784c2-07d1-5b73-a707-22d18b2e67d7",
    "external_key": "SAT_MATH:4a2264b3",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_TWO_VARIABLES",
    "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
    "difficulty": "EASY",
    "prompt": "The line graph shows the percent of cars for sale at a used car lot on a given day by model year (2010 to 2019). The plotted values are approximately:\n- 2010 to 2012: $12\\%$\n- 2013: $8\\%$\n- 2014: $4\\%$\n- 2015: $9\\%$\n- 2016 to 2017: $10\\%$\n- 2018 to 2019: $11\\%$\n\nFor what model year is the percent of cars for sale the smallest?",
    "options": [
      {
        "id": "08ebd493-18fd-37d5-a1ad-1d6f95f57fb0",
        "key": "A",
        "text": "2012"
      },
      {
        "id": "2a53e400-4a60-3e22-9d4f-419006100b15",
        "key": "B",
        "text": "2013"
      },
      {
        "id": "0815b853-98fe-38dd-b1c1-f3abbbe1c298",
        "key": "C",
        "text": "2014"
      },
      {
        "id": "4df42898-d61f-35f3-a615-19dcff930357",
        "key": "D",
        "text": "2015"
      }
    ],
    "correct_option_id": "0815b853-98fe-38dd-b1c1-f3abbbe1c298",
    "explanation": "Choice C is correct. The vertical axis represents the percent of cars for sale. The lowest point on the graph reaches approximately $4\\%$, which corresponds to the model year 2014 on the horizontal axis.",
    "source_id": "4a2264b3",
    "source_number": 116,
    "authored_distractors": false
  },
  {
    "id": "cf824efa-82a6-5188-a37a-3673bc4c5aa0",
    "external_key": "SAT_MATH:e3d49511",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_RATIOS_RATES_UNITS",
    "topic_name": "Problem-Solving and Data Analysis / Ratios, rates, proportional relationships, and units",
    "difficulty": "EASY",
    "prompt": "The number of raccoons in a 131-square-mile area is estimated to be 2,358. What is the estimated population density, in raccoons per square mile, of this area?",
    "options": [
      {
        "id": "e8ae5193-c4f3-3459-afa2-67e3c8db1486",
        "key": "A",
        "text": "18"
      },
      {
        "id": "c36123d5-fc57-3c62-914f-8204759bc10f",
        "key": "B",
        "text": "131"
      },
      {
        "id": "e9eec8fb-a6f6-353c-8e0f-340b8c683250",
        "key": "C",
        "text": "149"
      },
      {
        "id": "3c0966b1-fded-3e4d-9bde-fda64caaab0f",
        "key": "D",
        "text": "2,376"
      }
    ],
    "correct_option_id": "e8ae5193-c4f3-3459-afa2-67e3c8db1486",
    "explanation": "Choice A is correct. The estimated population density is:\n$$\\text{Density} = \\frac{2{,}358\\text{ raccoons}}{131\\text{ square miles}} = 18\\text{ raccoons per square mile}$$",
    "source_id": "e3d49511",
    "source_number": 117,
    "authored_distractors": false
  },
  {
    "id": "c87738a2-2f4b-5ecd-b0b1-1f967854413d",
    "external_key": "SAT_MATH:b680e76d",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_PROBABILITY",
    "topic_name": "Problem-Solving and Data Analysis / Probability and conditional probability",
    "difficulty": "EASY",
    "prompt": "A survey taken by 1,000 students at a school asked whether they played school sports. The table below summarizes all 1,000 responses from the students surveyed:\n\n| | Males | Females |\n| :--- | :---: | :---: |\n| **Play a school sport** | 312 | 220 |\n| **Do not play a school sport** | ? | 216 |\n\nHow many of the males surveyed responded that they do not play a school sport?",
    "options": [
      {
        "id": "50457945-454a-39cc-81f1-6ca49653e05f",
        "key": "A",
        "text": "109"
      },
      {
        "id": "1367bb18-c002-3e59-86b5-d434bde94c9e",
        "key": "B",
        "text": "252"
      },
      {
        "id": "497d0cce-15b2-309a-ab4c-c7a849d97a94",
        "key": "C",
        "text": "468"
      },
      {
        "id": "996a4003-2be2-30dd-b84d-ad4054ddaf12",
        "key": "D",
        "text": "688"
      }
    ],
    "correct_option_id": "1367bb18-c002-3e59-86b5-d434bde94c9e",
    "explanation": "Choice B is correct. The four categories must sum to the total of 1,000 students surveyed:\n$$312 + 220 + 216 + x = 1{,}000$$\n$$748 + x = 1{,}000 \\implies x = 1{,}000 - 748 = 252$$\nThus, 252 males responded that they do not play a school sport.",
    "source_id": "b680e76d",
    "source_number": 118,
    "authored_distractors": false
  },
  {
    "id": "5d712b3d-bfec-53f6-be5f-e3b8b1e0ba2b",
    "external_key": "SAT_MATH:c88e0663",
    "discipline_code": "SAT_MATH",
    "topic_code": "DATA_ONE_VARIABLE",
    "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
    "difficulty": "EASY",
    "prompt": "For a school fund-raiser, 10 students sold a total of 90 boxes of cookies. Which of the following can be calculated from this information?",
    "options": [
      {
        "id": "6dd9c66d-4680-3183-b78a-aac3c6224f72",
        "key": "A",
        "text": "The average number of boxes sold per student"
      },
      {
        "id": "30a7a2ed-9cc6-3acc-a965-79c68bc4a30c",
        "key": "B",
        "text": "The median number of boxes sold per student"
      },
      {
        "id": "e976faa1-9e52-32b0-afcf-be7cfe509303",
        "key": "C",
        "text": "The greatest number of boxes sold by one student"
      },
      {
        "id": "5a0ef29e-6b24-3700-b49f-eaec2a3a308e",
        "key": "D",
        "text": "The least number of boxes sold by one student"
      }
    ],
    "correct_option_id": "6dd9c66d-4680-3183-b78a-aac3c6224f72",
    "explanation": "Choice A is correct. The average (mean) number of boxes sold per student is:\n$$\\text{Average} = \\frac{\\text{Total boxes sold}}{\\text{Total students}} = \\frac{90}{10} = 9\\text{ boxes per student}$$\nCalculating the median, maximum, or minimum would require knowing the individual number of boxes sold by each student, which is not provided.",
    "source_id": "c88e0663",
    "source_number": 120,
    "authored_distractors": false
  },
  {
    "id": "87280a65-c502-5d19-94ef-358e93e01660",
    "external_key": "SAT_RW:f1bfbed3",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_INFERENCES",
    "topic_name": "Information and Ideas / Inferences",
    "difficulty": "HARD",
    "prompt": "Marta Coll and colleagues’ 2010 Mediterranean Sea biodiversity census reported approximately 17,000 species, nearly double the number reported in Carlo Bianchi and Carla Morri’s 2000 census—a difference only partly attributable to the description of new invertebrate species in the interim. Another factor is that the morphological variability of microorganisms is poorly understood compared to that of vertebrates, invertebrates, plants, and algae, creating uncertainty about how to evaluate microorganisms as species. Researchers’ decisions on such matters therefore can be highly consequential. Indeed, the two censuses reported similar counts of vertebrate, plant, and algal species, suggesting that ______\n\nWhich choice most logically completes the text?",
    "options": [
      {
        "id": "99ae041e-6688-3a08-b7ca-d5153817e232",
        "key": "A",
        "text": "Coll and colleagues reported a much higher number of species than Bianchi and Morri did largely due to the inclusion of invertebrate species that had not been described at the time of Bianchi and Morri’s census."
      },
      {
        "id": "020f9bc6-9cfa-373e-bfe7-886566f7a8d0",
        "key": "B",
        "text": "some differences observed in microorganisms may have been treated as variations within species by Bianchi and Morri but treated as indicative of distinct species by Coll and colleagues."
      },
      {
        "id": "59e8f22e-24ac-3d97-8716-2bc0a9279e1e",
        "key": "C",
        "text": "Bianchi and Morri may have been less sensitive to the degree of morphological variation displayed within a typical species of microorganism than Coll and colleagues were."
      },
      {
        "id": "8d8c542a-f3b4-34db-bf13-8850b14b9ab8",
        "key": "D",
        "text": "the absence of clarity regarding how to differentiate among species of microorganisms may have resulted in Coll and colleagues underestimating the number of microorganism species."
      }
    ],
    "correct_option_id": "020f9bc6-9cfa-373e-bfe7-886566f7a8d0",
    "explanation": "Choice B is the best answer because it presents the conclusion that most logically completes the text’s discussion of the different counts of species in the Mediterranean Sea. The text states that Coll and colleagues reported almost double the number of species that Bianchi and Morri reported in their study ten years earlier. According to the text, this difference can only be partly attributed to new invertebrate species being described in the years between the two studies, which means there must be an additional factor that made Coll and colleagues’ count so much higher than Bianchi and Morri’s count. The text goes on to explain that factor: researchers have a relatively poor understanding of microorganisms’ morphological variability, or the differences in microorganisms’ structure and form. This poor understanding makes it hard to classify microorganisms by species and means that researchers’ decisions about classifying microorganisms can have a large effect on the overall species counts that researchers report. Additionally, the text says that the two censuses reported similar numbers of vertebrate, plant, and algal species, which means that the difference in overall species did not come from differences in those categories. Given all this information, it most logically follows that Coll and colleagues may have treated some of the differences among microorganisms as indicative of the microorganisms being different species, whereas Bianchi and Morri treated those differences as variations within species, resulting in Coll and colleagues reporting many more species than Bianchi and Morri did.\n\nChoice A is incorrect because the text explicitly addresses this issue by stating that the description of new invertebrate species in the years between the two studies can explain only part of the difference in the number of species reported by the studies. The focus of the text is on explaining the difference between Coll and colleagues’ count and Bianchi and Morri’s count that cannot be accounted for by the inclusion of invertebrate species that had not been described at the time of Bianchi and Morri’s study. Choice C is incorrect because nothing in the text suggests that Bianchi and Morri may have been less sensitive to how much the form and structure of microorganisms vary within the same species than Coll and colleagues were. If Bianchi and Morri had been less sensitive to within-species variation than Coll and colleagues were, Bianchi and Morri would likely have reported more species than Coll and colleagues did, since less sensitivity to within-species variation would lead researchers to classify as different species microorganisms that more sensitive researchers would classify as variations within the same species. The text indicates, however, that Bianchi and Morri reported far fewer species than Coll and colleagues did; since the text also excludes other explanations for this difference, it suggests that in fact Bianchi and Morri were more sensitive to within-species variation than Coll and colleagues were, leading Bianchi and Morri to report fewer overall species. Choice D is incorrect because the text is focused on explaining why Coll and colleagues reported many more species than Bianchi and Morri did, and an underestimate of the number of microorganism species by Coll and colleagues would not explain that difference—it would suggest, in fact, that the difference in the number of species should have been even larger.",
    "source_id": "f1bfbed3",
    "source_number": 1,
    "authored_distractors": false
  },
  {
    "id": "847a92c3-35ef-5eb6-ad98-b107d53d4e8d",
    "external_key": "SAT_RW:6b8a7c74",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_INFERENCES",
    "topic_name": "Information and Ideas / Inferences",
    "difficulty": "HARD",
    "prompt": "One recognized social norm of gift giving is that the time spent obtaining a gift will be viewed as a reflection of the gift’s thoughtfulness. Marketing experts Farnoush Reshadi, Julian Givi, and Gopal Das addressed this view in their studies of norms specifically surrounding the giving of gift cards, noting that while recipients tend to view digital gift cards (which can be purchased online from anywhere and often can be redeemed online as well) as superior to physical gift cards (which sometimes must be purchased in person and may only be redeemable in person) in terms of usage, 94.8 percent of participants surveyed indicated that it is more socially acceptable to give a physical gift card to a recipient. This finding suggests that ______\n\nWhich choice most logically completes the text?",
    "options": [
      {
        "id": "bc10ad03-f955-3e9f-be5e-c4333121c0e4",
        "key": "A",
        "text": "gift givers likely overestimate the amount of effort required to use digital gift cards and thus mistakenly assume gift recipients will view them as less desirable than physical gift cards."
      },
      {
        "id": "3ae4f45f-c6e4-353e-bdbf-ed36f1f14a44",
        "key": "B",
        "text": "physical gift cards are likely preferred by gift recipients because the tangible nature of those cards offers a greater psychological sense of ownership than digital gift cards do."
      },
      {
        "id": "7c350d3e-c915-3a7a-9d0d-513268a050d3",
        "key": "C",
        "text": "physical gift cards are likely less desirable to gift recipients than digital gift cards are because of the perception that physical gift cards require unnecessary effort to obtain."
      },
      {
        "id": "f5918545-68ab-3ea0-9ff0-ea5cfed1508c",
        "key": "D",
        "text": "gift givers likely perceive digital gift cards as requiring relatively low effort to obtain and thus wrongly assume gift recipients will appreciate them less than they do physical gift cards."
      }
    ],
    "correct_option_id": "f5918545-68ab-3ea0-9ff0-ea5cfed1508c",
    "explanation": "Choice D is the best answer because it most logically completes the text’s discussion of perceptions of digital versus physical gift cards. The text begins by explaining that the perception of \"the time spent obtaining a gift…as a reflection of the gift’s thoughtfulness\" is a social norm of gift giving. The text then explains that although those who receive digital gift cards view them as easier to use than physical gift cards, a marketing study nonetheless showed that 94.8% of participants found physical gift cards more \"socially acceptable\" to give. The text specifically contrasts the ease with which digital gift cards \"can be purchased online from anywhere\" with the fact that physical gift cards \"sometimes must be purchased in person\"—suggesting the greater difficulty of obtaining physical cards. Given the text’s initial premise that gift-giving norms equate the thoughtfulness of a gift with the effort involved in acquiring that gift, it is reasonable to infer that people perceive digital gift cards as requiring less effort to obtain and thus assume recipients will appreciate them less, even though recipients actually prefer gift cards in the more usable digital format.\n\nChoice A is incorrect. Although the text does discuss recipients’ preference of digital versus physical gift cards and the relative ease with which the two formats can be used, it doesn’t consider the misconceptions that gift givers may have of these factors. Moreover, the text establishes that recipients regard digital gift cards as easier to use and therefore preferable to physical gift cards. Choice B is incorrect because the text doesn’t consider whether recipients of gift cards feel a sense of ownership toward them, nor does the text touch on the greater tangibility of physical versus digital gift cards. Instead, the text contrasts the two formats of gift cards in terms of their respective usability and the difficulty involved in acquiring them and discusses how those factors influence people’s perceptions of the two formats. Choice C is incorrect because it contradicts the text, which explains that recipients regard digital gift cards as superior to physical ones because they are easier to use than physical cards, not because physical gift cards require greater effort to obtain than digital gift cards do. Moreover, the text doesn’t characterize the effort required to obtain physical gift cards as \"unnecessary.\"",
    "source_id": "6b8a7c74",
    "source_number": 2,
    "authored_distractors": false
  },
  {
    "id": "13809116-e088-5fc7-b7a2-6960f4d4f5ef",
    "external_key": "SAT_RW:a15b3219",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "HARD",
    "prompt": "**Municipalities’ Responses to Inquiries about Potential Incentives for Firm**\n*(Data from Graph: Number of municipalities surveyed)*\n- **No response:** Announcement before election (~1,250); Announcement after election (~1,240)\n- **Responded to inquiry:** Announcement before election (~200); Announcement after election (~200)\n- **Offered incentive:** Announcement before election (~100); Announcement after election (~100)\n\nIn the United States, firms often seek incentives from municipal governments to expand to those municipalities. A team of political scientists hypothesized that municipalities are much more likely to respond to firms and offer incentives if expansions can be announced in time to benefit local elected officials than if they can’t. The team contacted officials in thousands of municipalities, inquiring about incentives for a firm looking to expand and indicating that the firm would announce its expansion on a date either just before or just after the next election.\n\nWhich choice best describes data from the graph that weaken the team’s hypothesis?",
    "options": [
      {
        "id": "b1834537-8bb4-390d-a676-7f1fa79fe817",
        "key": "A",
        "text": "A large majority of the municipalities that received an inquiry mentioning plans for an announcement before the next election didn’t respond to the inquiry."
      },
      {
        "id": "30eadb36-61aa-3efe-9673-71483e212297",
        "key": "B",
        "text": "The proportion of municipalities that responded to the inquiry or offered incentives didn’t substantially differ across the announcement timing conditions."
      },
      {
        "id": "b4c091e4-4f1c-3e2b-ba8e-728dbe278e18",
        "key": "C",
        "text": "Only around half the municipalities that responded to inquiries mentioning plans for an announcement before the next election offered incentives."
      },
      {
        "id": "1d2288ef-c203-3d17-9e59-27e513454ab3",
        "key": "D",
        "text": "Of the municipalities that received an inquiry mentioning plans for an announcement date after the next election, more than 1,200 didn’t respond and only around 100 offered incentives."
      }
    ],
    "correct_option_id": "30eadb36-61aa-3efe-9673-71483e212297",
    "explanation": "Choice B is the best answer. The text explains that firms in the United States often look to municipal governments (local governing bodies) for incentives to expand the firms into those areas. The text then indicates that a team of political scientists hypothesized that those governing bodies are much more likely to respond and offer incentives when the expansion (if there’s going to be one) can be announced before an election, since announcing a firm coming to their area can benefit local elected officials. However, the graph—which presents the results of the political scientists’ inquiries to municipalities about incentives for a firm in two timing scenarios—shows that the proportion of municipalities that responded to the inquiry or offered incentives didn’t substantially differ based on timing. According to the graph, about 200 municipalities responded to the inquiry and about 100 offered an incentive when the announcement could be made before an election (represented by the gray bars) and about 200 municipalities responded to the inquiry and about 100 offered an incentive when the announcement would be made after an election (represented by the black bars). These data weaken the team’s hypothesis by demonstrating that municipalities are not much more likely to respond and offer incentives when the timing means they could announce an expansion before an election.\n\nChoice A is incorrect. Although the graph does show that a large number of municipalities didn’t respond to inquiries in the scenario in which an expansion announcement could be made before an election (represented by the gray bars), the text indicates that the team hypothesized that there would be a substantial difference in municipalities’ actions based on timing, and information about only one timing scenario doesn’t reveal anything about whether such a difference occurred. Choice C is incorrect. The graph does show that in the scenario in which an expansion announcement could be made before an election (represented by the gray bars), about 200 municipalities responded to inquiries and about 100 offered an incentive, but the text indicates that the team hypothesized that there would be a substantial difference in municipalities’ actions based on timing, and information about only one timing scenario doesn’t reveal anything about whether such a difference occurred. Choice D is incorrect. Although this choice accurately describes data from the graph for the scenario in which an expansion announcement would be made after an election (represented by the black bars), the text indicates that the team hypothesized that there would be a substantial difference in municipalities’ actions based on timing, and information about only one timing scenario doesn’t reveal anything about whether such a difference occurred.",
    "source_id": "a15b3219",
    "source_number": 3,
    "authored_distractors": false
  },
  {
    "id": "30a4e38a-0466-5da3-a31b-d014fad7ca16",
    "external_key": "SAT_RW:ed314256",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "HARD",
    "prompt": "The most recent iteration of the immersive theater experience *Sleep No More*, which premiered in New York City in 2011, transforms its performance space—a five-story warehouse—into a 1930s-era hotel. Audience members, who wander through the labyrinthine venue at their own pace and follow the actors as they play out simultaneous, interweaving narrative loops, confront the impossibility of experiencing the production in its entirety. The play’s refusal of narrative coherence thus hinges on the sense of spatial fragmentation that the venue’s immense and intricate layout generates.\n\nWhat does the text most strongly suggest about *Sleep No More*’s use of its performance space?",
    "options": [
      {
        "id": "fd9198c2-15d8-3a86-8432-86fcdd22cb69",
        "key": "A",
        "text": "The choice of a New York City venue likely enabled the play’s creators to experiment with the use of theatrical space in a way that venues from earlier productions could not."
      },
      {
        "id": "4b5a21c2-6fa3-31ad-a7c3-ac6d55abd5f6",
        "key": "B",
        "text": "Audience members likely find the experience of the play disappointing because they generally cannot make their way through the entire venue."
      },
      {
        "id": "888a97ca-4b66-3703-aeb6-d76104526910",
        "key": "C",
        "text": "The production’s dependence on a particular performance environment would likely make it difficult to reproduce exactly in a different theatrical space."
      },
      {
        "id": "2484e2d2-7862-3838-8064-7b29bfb5b37d",
        "key": "D",
        "text": "Audience members who navigate the space according to a recommended itinerary will likely have a better grasp of the play’s narrative than audience members who depart from that itinerary."
      }
    ],
    "correct_option_id": "888a97ca-4b66-3703-aeb6-d76104526910",
    "explanation": "Choice C is the best answer. The text says that the production’s use of its large, winding space has a very specific effect on the audience. Given that the space itself is so important to creating this effect, it would be difficult to reproduce the production in a different space.\n\nChoice A is incorrect. The fact that the venue is in New York City isn’t connected to the experimental nature of the performance. It’s the size of the venue, not its location in New York, that affects the theatrical experience. Choice B is incorrect. The text never suggests that audience members are disappointed because they can’t see the entire production. In fact, it suggests that that’s an important part of the experience. Choice D is incorrect. The text doesn’t mention a recommended itinerary for audience members.",
    "source_id": "ed314256",
    "source_number": 4,
    "authored_distractors": false
  },
  {
    "id": "45e6ae4d-a07b-5745-adb0-402ebcf915fb",
    "external_key": "SAT_RW:2903668a",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "HARD",
    "prompt": "The interiors of many temples in the ancient Middle East needed to satisfy a precise set of acoustic demands: the sounds of chants and hymns should travel with clarity, while profound silences should be fully felt and appreciated. In a research paper, a student claims that the users of one such temple were aware of how the materials that were used within the structure could affect sound quality and that they deliberately applied this knowledge to influence how sound was experienced in the space.\n\nWhich quotation from a work by a historian would most directly support the student’s claim?",
    "options": [
      {
        "id": "96ac458b-d80e-35fa-b1e2-30156e280c12",
        "key": "A",
        "text": "“Many researchers believe that the central chamber of the temple had a high ceiling, a feature that has since become essential to the acoustic design of modern concert halls.”"
      },
      {
        "id": "03ce52d0-8dc2-3a4c-b9a3-73856bbe93a8",
        "key": "B",
        "text": "“The innermost room of the temple was likely among the quietest spaces in the interior of the temple.”"
      },
      {
        "id": "c648b9f7-b14b-34df-9aca-5e331afeddd4",
        "key": "C",
        "text": "“The acoustic environment of the temple was best suited for music that eschewed ornamentation in favor of simple melodies, harmonies, and rhythms.”"
      },
      {
        "id": "5b96cf7d-148e-3ae3-97ed-d4aa5184cdef",
        "key": "D",
        "text": "“During special occasions, curtains were placed inside the temple to minimize reverberation and confine the sound to designated locations.”"
      }
    ],
    "correct_option_id": "5b96cf7d-148e-3ae3-97ed-d4aa5184cdef",
    "explanation": "Choice D is the best answer because it provides a quotation that would most directly support the student’s claim that the temple’s users were aware of how materials used in the temple affected sound and deliberately applied that knowledge to shape the sonic experience of people in the space. The quotation indicates that curtains would, at times, be installed specifically “to minimize reverberation and confine the sound,” thereby illustrating that the users of the temple had knowledge of the acoustic properties of materials within the temple (how curtains dampen sound) and employed this knowledge to affect the experience of sound within the space.\n\nChoice A is incorrect. Although the quotation describes a feature of the temple’s structure (the high ceiling), it makes no mention of the materials used, the materials’ acoustic properties, or temple users’ awareness of how materials impact sound quality. Choice B is incorrect because it doesn’t address any materials that were used in the temple, let alone their acoustic properties or temple users’ awareness of how materials impact sound quality. Choice C is incorrect because it doesn’t address any materials that were used in the temple, let alone their acoustic properties or temple users’ awareness of how materials impact sound quality.",
    "source_id": "2903668a",
    "source_number": 5,
    "authored_distractors": false
  },
  {
    "id": "3297395f-aab4-5c59-9134-6aa2f4dba01f",
    "external_key": "SAT_RW:22e4d633",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "HARD",
    "prompt": "Although many transposons, DNA sequences that move within an organism’s genome through shuffling or duplication, have become corrupted and inactive over time, those from the long interspersed nuclear elements (LINE) family appear to remain active in the genomes of some species. In humans, they are functionally important within the hippocampus, a brain structure that supports complex cognitive processes. When the results of molecular analysis of two species of octopus—an animal known for its intelligence—were announced in 2022, the confirmation of a LINE transposon in *Octopus vulgaris* and *Octopus bimaculoides* genomes prompted researchers to hypothesize that that transposon family is tied to a species’ capacity for advanced cognition.\n\nWhich finding, if true, would most directly support the researchers’ hypothesis?",
    "options": [
      {
        "id": "8f3d6bfb-7804-3411-9851-cac2da372d0b",
        "key": "A",
        "text": "The LINE transposon in *O. vulgaris* and *O. bimaculoides* genomes is active in an octopus brain structure that functions similarly to the human hippocampus."
      },
      {
        "id": "b3fcfc78-22fd-3b96-bf3d-489ae77cea92",
        "key": "B",
        "text": "The human genome contains multiple transposons from the LINE family that are all primarily active in the hippocampus."
      },
      {
        "id": "365ad49c-3872-3e7d-a536-eeaac70ebbdd",
        "key": "C",
        "text": "A consistent number of copies of LINE transposons is present across the genomes of most octopus species, with few known corruptions."
      },
      {
        "id": "f843690b-3ead-3c6e-9899-518b9b7061fb",
        "key": "D",
        "text": "*O. vulgaris* and *O. bimaculoides* have smaller brains than humans do relative to body size, but their genomes contain sequences from a wider variety of transposon families."
      }
    ],
    "correct_option_id": "8f3d6bfb-7804-3411-9851-cac2da372d0b",
    "explanation": "Choice A is the best answer. The text says that LINE transposons are important in the human hippocampus, which supports complex cognition. If the LINE transposon found in octopuses is active in a similar part of their brain, that would suggest that LINE transposons support complex cognition in octopuses too, which in turn supports the hypothesis that LINE transposons are linked to advanced cognition in general.\n\nChoice B is incorrect. This choice doesn’t support the hypothesis. It doesn’t include anything about how LINE transposons function in species other than humans. Choice C is incorrect. This choice doesn’t support the hypothesis. It doesn’t include anything about how the LINE transposon in octopuses might support advanced cognition. Choice D is incorrect. This choice doesn’t support the hypothesis. It doesn’t include anything about how the LINE transposon in octopuses might support advanced cognition.",
    "source_id": "22e4d633",
    "source_number": 6,
    "authored_distractors": false
  },
  {
    "id": "c7c87f02-0068-5777-9551-2fabc9fc9baf",
    "external_key": "SAT_RW:458b4a11",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "HARD",
    "prompt": "To understand how temperature change affects microorganism-mediated cycling of soil nutrients in alpine ecosystems, Eva Kaštovská et al. collected plant-soil cores in the Tatra Mountains at elevations around 2,100 meters and transplanted them to elevations of 1,700–1,800 meters, where the mean air temperature was warmer by 2°C. Microorganism-mediated nutrient cycling was accelerated in the transplanted cores; crucially, microorganism community composition was unchanged, allowing Kaštovská et al. to attribute the acceleration to temperature-induced increases in microorganism activity.\n\nIt can most reasonably be inferred from the text that the finding about the microorganism community composition was important for which reason?",
    "options": [
      {
        "id": "59d8d908-2306-3616-912c-40e9a49f4613",
        "key": "A",
        "text": "It provided preliminary evidence that microorganism-mediated nutrient cycling was accelerated in the transplanted cores."
      },
      {
        "id": "12b2b1c9-c4d2-3204-ab33-a41dad0e568e",
        "key": "B",
        "text": "It suggested that temperature-induced changes in microorganism activity may be occurring at increasingly high elevations."
      },
      {
        "id": "869f6e8d-9a4c-30f6-85a8-43dbb752e6a3",
        "key": "C",
        "text": "It ruled out a potential alternative explanation for the acceleration in microorganism-mediated nutrient cycling."
      },
      {
        "id": "17f8722a-751d-34ce-a2c8-92e871244f2d",
        "key": "D",
        "text": "It clarified that microorganism activity levels in the plant-soil cores varied depending on which microorganisms comprised the community."
      }
    ],
    "correct_option_id": "869f6e8d-9a4c-30f6-85a8-43dbb752e6a3",
    "explanation": "Choice C is the best answer because it accurately describes why the finding about the microorganism community composition was important. The text describes an experiment by Eva Kaštovská and her team in which they collected plant-soil cores at one elevation and transplanted them to sites at a lower elevation, where the mean air temperature was warmer. Kaštovská and her team observed that microorganism-mediated nutrient cycling was accelerated in the transplanted cores and that \"crucially, microorganism community composition was unchanged,\" which allowed the team to attribute the acceleration to changes in microorganism activity brought about by the difference in temperature. This strongly implies that the team wouldn’t have been able to make that attribution otherwise, meaning that a change in microorganism composition represented another possible explanation for the acceleration that had to be ruled out.\n\nChoice A is incorrect. Although the text says microorganism-mediated cycling of soil nutrients increased in the transplanted cores, this is unrelated to what’s important about the finding that the microorganism composition didn’t change—that it allowed the team to attribute the change in activity solely to the change in temperature. Choice B is incorrect. Although the text compares activity in one core at two different elevations, the text doesn’t address changes in activity at various elevations over time. Choice D is incorrect. Although different microorganisms likely exhibit different levels of activity, the text indicates that there was no change in microorganism composition, and there is nothing in the text about different microorganisms having different activity levels.",
    "source_id": "458b4a11",
    "source_number": 7,
    "authored_distractors": false
  },
  {
    "id": "82d0fea8-22c0-5095-b732-db395b6f3876",
    "external_key": "SAT_RW:0d7f4966",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "HARD",
    "prompt": "Jean-Bernard Caron and colleagues recently discovered a cache of jellyfish fossils in the Burgess Shale, a site in the Canadian Rockies that is rich in fossils from the Cambrian period (over 500 million years ago). Caron and colleagues claim that these are the oldest jellyfish fossils ever discovered. In the past twenty years, two sites in China and the United States have yielded fossils of a similar age that some experts believe are most likely jellyfish due to their shapes and the appearance of projecting tentacles. But Caron and colleagues argue that the apparent tentacles are in fact the comb rows of ctenophores, gelatinous animals that are only distantly related to jellyfish.\n\nWhich statement, if true, would most directly weaken the claim by Caron and colleagues about the fossils found in China and the United States?",
    "options": [
      {
        "id": "48452f6d-a8b8-3f43-a089-9eb78e0d3ebd",
        "key": "A",
        "text": "Sites in the Canadian Rockies from later periods than the Cambrian period have yielded fossils that have been conclusively identified as ctenophore fossils."
      },
      {
        "id": "a7aa656d-3751-3052-9fd3-28e1a7b4d0e4",
        "key": "B",
        "text": "The fossils found in China and the United States are so poorly preserved that though they cannot be conclusively identified as jellyfish, they cannot be conclusively identified as ctenophores either."
      },
      {
        "id": "8ade46ec-6376-3ba0-9d20-488b29d4273a",
        "key": "C",
        "text": "While ctenophore fossils have been discovered in China and the United States, they have never been discovered in the Burgess Shale."
      },
      {
        "id": "08943238-3379-39bb-a8d0-bce6d2fc7e55",
        "key": "D",
        "text": "The fossils discovered by Caron and colleagues in the Burgess Shale were better preserved than the fossils discovered by other researchers in China and the United States."
      }
    ],
    "correct_option_id": "a7aa656d-3751-3052-9fd3-28e1a7b4d0e4",
    "explanation": "Choice B is the best answer because it presents a statement that, if true, would most directly weaken Caron and colleagues’ claim that the apparent tentacles in the Chinese and American fossils are actually ctenophore comb rows. If the fossils are so poorly preserved that they cannot be conclusively identified as either organism, neither the claim that they are jellyfish nor, as Caron claims, that they are ctenophores would be supported.\n\nChoice A is incorrect. Caron’s claim is that fossils from the US and China are ctenophores, not jellyfish. These fossils are said to be \"of a similar age\" to the Cambrian fossils found in the Canadian Rockies. And nothing in the text or this choice suggests that the presence or absence of ctenophores after the Cambrian would have any bearing on whether the Cambrian fossils from the US and China are ctenophores. Choice C is incorrect. Caron’s claim is that fossils from the US and China are ctenophores, not jellyfish. Nothing in the text suggests that the presence or absence of ctenophores in the Burgess Shale (in Canada) would affect whether the fossils found in the US and China are ctenophores. Choice D is incorrect. Caron’s claim is that fossils from the US and China are ctenophores, not jellyfish. Although fossil quality is a plausible issue for the research described in the text, nothing in the text or this choice suggests that the fossils from US and China would have been too poorly preserved for proper identification.",
    "source_id": "0d7f4966",
    "source_number": 8,
    "authored_distractors": false
  },
  {
    "id": "fcf54299-b6f8-507e-9cac-a13abd67d3dc",
    "external_key": "SAT_RW:1ba5ad7a",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "HARD",
    "prompt": "Many literary theorists distinguish between fabula, a narrative’s content, and syuzhet, a narrative’s arrangement and presentation of events. In the film *The Godfather Part II*, the fabula is the story of the Corleone family, and the syuzhet is the presentation of the story as it alternates between two timelines in 1901 and 1958. But literary theorist Mikhail Bakhtin maintained that fabula and syuzhet are insufficient to completely describe a narrative—he held that systematic categorizations of artistic phenomena discount the subtle way in which meaning is created by interactions between the artist, the work, and the audience.\n\nWhich choice best states the main idea of the text?",
    "options": [
      {
        "id": "395f4bac-2619-3529-8fbd-c1c84e3f6bb6",
        "key": "A",
        "text": "Literary theorist Mikhail Bakhtin argued that there are important characteristics of narratives that are not fully encompassed by two concepts that other theorists have used to analyze narratives."
      },
      {
        "id": "f775d8af-2dd8-3552-97d4-2821e49acb94",
        "key": "B",
        "text": "Literary theorist Mikhail Bakhtin claimed that meaning is not inherent in a narrative but is created when an audience encounters a narrative so that narratives are interpreted differently by different people."
      },
      {
        "id": "ce057d9b-5f57-3c33-a893-f1bf3c100fbe",
        "key": "C",
        "text": "The storytelling methods used in *The Godfather Part II* may seem unusually complicated, but they can be easily understood when two concepts from literary theory are utilized."
      },
      {
        "id": "4a9e71c3-3c4d-3e23-9e0e-55929b501d13",
        "key": "D",
        "text": "Narratives that are told out of chronological order are more difficult for audiences to understand than are narratives presented chronologically."
      }
    ],
    "correct_option_id": "395f4bac-2619-3529-8fbd-c1c84e3f6bb6",
    "explanation": "Choice A is the best answer because it most accurately states the main idea of the text. The text begins by explaining that many literary theorists rely on the concepts of fabula (a narrative’s content) and syuzhet (a narrative’s arrangement and presentation of events) and illustrates these concepts by explaining how they can be applied to the film *The Godfather Part II*. The text then discusses how Mikhail Bakhtin, a literary theorist, argued that fabula and syuzhet can’t fully describe a narrative, since systematic categorizations such as these fail to account for all the ways in which interactions between the artist, the work, and the audience produce meaning. Thus, the main idea is that Bakhtin argued that there are important characteristics of narratives that are not fully encompassed by two concepts that other theorists have used to analyze narratives.\n\nChoice B is incorrect because according to the text, Mikhail Bakhtin believed that meaning was created through the interactions of the artist, narrative, and audience, not simply through the interaction between the audience and narrative; moreover, the text doesn’t address whether Bakhtin focused on the ways in which different people interpret narratives differently. Choice C is incorrect. Although the text implies that the storytelling methods used in *The Godfather Part II* are complicated, it discusses the film only to illustrate how the concepts of fabula and syuzhet may be applied to a narrative. The film’s storytelling methods aren’t the primary focus of the text. Choice D is incorrect. The text discusses *The Godfather Part II*, whose narrative doesn’t adhere to a single chronological order, only to illustrate the concepts of fabula (a narrative’s content) and syuzhet (a narrative’s arrangement and presentation of events). The primary focus of this text isn’t the structure of this film or of other narratives that are told out of chronological order; moreover, the text doesn’t consider whether such structures make it harder for audiences to understand narratives.",
    "source_id": "1ba5ad7a",
    "source_number": 9,
    "authored_distractors": false
  },
  {
    "id": "02d67ae8-0be1-5083-83c6-147738deef1a",
    "external_key": "SAT_RW:068f939b",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "HARD",
    "prompt": "The ancient Greek concept of “mimesis,” a term used in the works of Plato, Aristotle, and other Greek philosophers in discussions of representational art—visual, performance, or literary art that aims to depict the real world—is a foundational concept of the Western philosophy of aesthetics. Mimesis is typically translated as “imitation” in modern editions of ancient Greek texts, but scholar Stephen Halliwell warns that this is overly reductive: “imitation” implies that art merely copies—and is thus by definition entirely derivative of—a reality that exists outside and prior to the work of art, and translating “mimesis” thusly obscures the multifaceted ways in which the ancient Greeks understood the relationship between art and reality.\n\nWhich statement, if true, would most directly support the claim by Halliwell presented in the text?",
    "options": [
      {
        "id": "69665232-b47b-3daa-9a0c-125fb92acf10",
        "key": "A",
        "text": "One of the earliest appearances of mimesis’s root word, *mimos*, can be found in an ancient Greek tragedy in reference to dramatic impersonation, and the *mim-* root came to be generally associated with the musical and poetic arts by the fifth century BCE."
      },
      {
        "id": "cafc187c-b147-3f7c-a3fb-4cd26f0eb29e",
        "key": "B",
        "text": "Both Plato’s and Aristotle’s theorizations of mimesis examine the psychological effects that works of art induce in the viewer or listener."
      },
      {
        "id": "ced28a8d-70fc-310a-852f-67dd3aba42e9",
        "key": "C",
        "text": "Although several of Plato’s earliest philosophical works discuss aesthetic ideas, the term “mimesis” doesn’t appear in Plato’s discussions of art until *Cratylus*, a relatively late work."
      },
      {
        "id": "ed6ec311-f986-38d2-9cb2-594a4b6914ff",
        "key": "D",
        "text": "Although Plato’s writings typically characterize representational art as an inferior reflection of the physical world, Aristotle suggests that mimesis can refer to art’s capacity to envision hypothetical conditions that could, but don’t yet, exist."
      }
    ],
    "correct_option_id": "ed6ec311-f986-38d2-9cb2-594a4b6914ff",
    "explanation": "Choice D is the best answer because it presents a statement that would support Halliwell’s claim that \"imitation\" is an overly simplified translation of the word \"mimesis\" in the context of ancient Greek philosophical discussions of representational art and that, because it suggests a view of art as merely copying things that exist in reality, the translation obscures the fact that Plato, Aristotle, and other ancient Greeks understood the relationship between art and reality in varied ways. If Plato’s works tend to treat representational art as an inferior or inadequate reflection of the physical world (consistent with the idea of mere imitation), while Aristotle’s works suggest that the term \"mimesis\" can refer to art’s ability to show conditions that don’t currently exist but could exist (going beyond imitation into novel creation), that evidence would support the claim that the term \"mimesis\" means more than just \"imitation\" and that ancient Greek philosophers held different views of the relationship between art and reality.\n\nChoice A is incorrect because information about the root word *mimos* first being used in drama and the root *mim-* coming to be associated with music and poetry wouldn’t indicate anything about the meaning of the specific term \"mimesis\" as it was used by ancient Greek philosophers in discussions of representational art; thus, the information would have no bearing on Halliwell’s claim that a common translation of the specific term is an oversimplification. Choice B is incorrect because the issue of art’s psychological effects on audiences gets at how people respond to works of art instead of how art itself is related to reality, so the idea that Plato and Aristotle both addressed such effects in their considerations of mimesis wouldn’t have any bearing on Halliwell’s claim that a common translation of that term oversimplifies the relationship between art and reality. Further, this idea would touch on one general similarity in approaches to mimesis instead of illustrating the multifaceted, or varied, ways Halliwell claims ancient Greek philosophers understood art’s relation to reality. Choice C is incorrect because the idea that Plato discussed aesthetics in his early works but didn’t use the term \"mimesis\" until later doesn’t give any indication of how Plato or any other ancient Greek philosophers understood the relation between art and reality, so it would have no bearing on Halliwell’s claim that a common translation of the term \"mimesis\" is oversimplified and fails to reflect the varied ways the philosophers understood that relationship.",
    "source_id": "068f939b",
    "source_number": 10,
    "authored_distractors": false
  },
  {
    "id": "dfa9299e-077e-5511-bfda-c7103695b3d8",
    "external_key": "SAT_RW:82cb7dda",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "HARD",
    "prompt": "The field of study called affective neuroscience seeks instinctive, physiological causes for feelings such as pleasure or displeasure. Because these sensations are linked to a chemical component (for example, the release of the neurotransmitter dopamine in the brain when one receives or expects a reward), they can be said to have a partly physiological basis. These processes have been described in mammals, but Jingnan Huang and his colleagues have recently observed that some behaviors of honeybees (such as foraging) are also motivated by a dopamine-based signaling process.\n\nWhat choice best describes the main purpose of the text?",
    "options": [
      {
        "id": "c25fe7c0-45a3-3550-a6fa-ba87c25ca614",
        "key": "A",
        "text": "It describes an experimental method of measuring the strength of physiological responses in humans."
      },
      {
        "id": "4c81f5b4-8dbf-3bc9-bf97-5d19bb4b8b5e",
        "key": "B",
        "text": "It illustrates processes by which certain insects can express how they are feeling."
      },
      {
        "id": "3edda84e-c857-38d3-ae4b-1500600cec66",
        "key": "C",
        "text": "It summarizes a finding suggesting that some mechanisms in the brains of certain insects resemble mechanisms in mammalian brains."
      },
      {
        "id": "9a96c580-cf9b-34f0-abb8-7de6b593faa4",
        "key": "D",
        "text": "It presents research showing that certain insects and mammals behave similarly when there is a possibility of a reward for their actions."
      }
    ],
    "correct_option_id": "3edda84e-c857-38d3-ae4b-1500600cec66",
    "explanation": "Choice C is the best answer because it most accurately describes the main purpose of the text, which is to summarize a finding suggesting that some mechanisms in the brains of certain insects resemble mechanisms in mammalian brains. The text begins by explaining that feelings such as pleasure and displeasure are linked to chemical processes in the brain, such as the release of dopamine when one receives a reward. The text then indicates that such processes have been seen in mammals but that researchers have recently observed similar processes involving dopamine in honeybees. Taken together, this information serves to sum up the discovery that some mechanisms in the brains of certain insects may resemble mechanisms linked to feelings such as pleasure and displeasure in mammals.\n\nChoice A is incorrect because the text doesn’t describe any experiments or experimental methods. Instead, the text describes a phenomenon that has been observed in mammals and then presents the recent observations of Huang and colleagues that this phenomenon is also seen in honeybees. Choice B is incorrect because there’s nothing in the text to suggest that certain insects can express how they’re feeling through particular processes. The text does indicate that certain honeybee behaviors such as foraging are linked to dopamine, but it doesn’t suggest that these behaviors enable honeybees to communicate feelings or sensations. Choice D is incorrect because the text presents research showing that certain honeybee behaviors such as foraging are linked to dopamine and therefore may be motivated by similar mechanisms to those in mammalian brains, not that honeybees and mammals behave similarly when there is the possibility of reward for their actions.",
    "source_id": "82cb7dda",
    "source_number": 11,
    "authored_distractors": false
  },
  {
    "id": "2cf65a45-da03-5714-a854-ffb676f50ce4",
    "external_key": "SAT_RW:e35d481c",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "HARD",
    "prompt": "Some economic historians ______ that late nineteenth- and early twentieth-century households in the United States experienced an economy of scale when it came to food purchases—they assumed that large households spent less on food per person than did small households. Economist Trevon Logan showed, however, that a close look at the available data disproves this supposition.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "ea4b16ab-aa68-3a59-98c8-b268a5a37dcb",
        "key": "A",
        "text": "surmised"
      },
      {
        "id": "a9269ed5-d7ee-3aee-8766-12454aec07a1",
        "key": "B",
        "text": "contrived"
      },
      {
        "id": "af822064-6433-3933-a496-f03da072f0cb",
        "key": "C",
        "text": "questioned"
      },
      {
        "id": "7317ae1b-a368-3458-b1b2-0a60c80c3e7b",
        "key": "D",
        "text": "regretted"
      }
    ],
    "correct_option_id": "ea4b16ab-aa68-3a59-98c8-b268a5a37dcb",
    "explanation": "Choice A is the best answer because it most logically completes the text’s discussion of late nineteenth- and early twentieth-century household food purchases. In this context, “surmised” means formed an idea or assumption with little evidence. The text explains that certain economic historians “assumed” that large and small households spent different amounts on food per person, but that another economist found this supposition to be false based on evidence from available data. This context suggests that the economic historians made an incorrect assumption without enough consideration of evidence.\n\nChoice B is incorrect. In this context, “contrived” would mean brought about or created through trickery. Nothing in the text suggests that the economic historians were deliberately trying to trick people with a claim about food purchasing behaviors in late nineteenth- and early twentieth-century households; the text simply suggests that they made an assumption about those behaviors that another historian believes isn’t supported by the available data. Choice C is incorrect because the text indicates that it’s Logan and not the economic historians who “questioned,” or doubted, the assumption that large and small households in the late nineteenth and early twentieth centuries spent different amounts on food per person; the economic historians are the ones who made that assumption to begin with. Choice D is incorrect because nothing in the text suggests that some economic historians “regretted,” or felt sad or remorseful about, the food purchasing behaviors of late nineteenth- and early twentieth-century households. The text focuses on the idea that the economic historians made an assumption about those behaviors that may not be supported by available data, not on the historians’ emotional response to what households did in the past.",
    "source_id": "e35d481c",
    "source_number": 12,
    "authored_distractors": false
  },
  {
    "id": "71ac1e68-c7bc-5c39-8361-19ffb0f9a99c",
    "external_key": "SAT_RW:5e57efec",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "HARD",
    "prompt": "Economist Marco Castillo and colleagues showed that nuisance costs—the time and effort people must spend to make donations—reduce charitable giving. Charities can mitigate this effect by compensating donors for nuisance costs, but those costs, though variable, are largely ______ donation size, so charities that compensate donors will likely favor attracting a few large donors over many small donors.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "a606848b-ceed-3b97-9863-2b038d23614f",
        "key": "A",
        "text": "supplemental to"
      },
      {
        "id": "09cf09d2-4f72-3fbe-b034-137ba29e6735",
        "key": "B",
        "text": "predictive of"
      },
      {
        "id": "581d105e-87df-3461-9e29-cf1945a98745",
        "key": "C",
        "text": "independent of"
      },
      {
        "id": "9a2ee885-8777-3676-b645-cda6904b130b",
        "key": "D",
        "text": "subsumed in"
      }
    ],
    "correct_option_id": "581d105e-87df-3461-9e29-cf1945a98745",
    "explanation": "Choice C is the best answer. We’re told that charities that pay donors back for nuisance costs will attract a few large donors instead of many small donors. This suggests that nuisance costs are not linked to donation size.\n\nChoice A is incorrect. This doesn’t fit the logic of the text. If nuisance costs are supplemental to (meaning in addition to) donation size, that wouldn’t result in charities that compensate donors for those costs attracting a few large donors over many small donors. Choice B is incorrect. This doesn’t fit the logic of the text. If nuisance costs can predict donation size, that wouldn’t necessarily result in charities that compensate donors for those costs attracting a few large donors over many small donors. Choice D is incorrect. This doesn’t fit the logic of the text. If nuisance costs are subsumed in (meaning included in) donation size, that wouldn’t result in charities that compensate donors for those costs attracting a few large donors over many small donors.",
    "source_id": "5e57efec",
    "source_number": 13,
    "authored_distractors": false
  },
  {
    "id": "04db7215-8f18-548d-ac03-ecd3da651658",
    "external_key": "SAT_RW:1917ba9a",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_CROSS_TEXT_CONNECTIONS",
    "topic_name": "Craft and Structure / Cross-Text Connections",
    "difficulty": "HARD",
    "prompt": "**Text 1**\nMany teleost fish species are protogynous, meaning that fertile females can become fertile males. One model holds that protogyny occurs when body size confers a greater reproductive advantage on males than on females. In teleost fish, body size is irrelevant to female reproduction, but among males (which tend to be larger than females), only individuals comparatively large enough to defend territory reproduce. An individual could thus maximize its lifetime reproductive success by staying female when small and becoming male upon reaching a critical size threshold.\n\n**Text 2**\nInvestigating protogyny in teleost fish, Alexander Goikoetxea and colleagues placed captured spotty wrasses of typical size distributions into two mixed-sex tanks. During the breeding season, they removed all males from tank 1 but none from tank 2. They observed that sexual change began in 81 percent of females in tank 1 but in no females in tank 2.\n\nBased on the texts, which choice best explains the difference in the outcomes of the two tanks in Goikoetxea and colleagues’ experiment (Text 2) using the model presented in Text 1?",
    "options": [
      {
        "id": "6aa80cd5-1339-34b0-8413-e4e9c6bdefd8",
        "key": "A",
        "text": "Once the males were removed from tank 1, territories in the tank were undefended and thus even small females could maximize their reproductive success by becoming male and taking over those territories, whereas only the largest females in tank 2 could successfully take over territories due to the ongoing presence of males in the tank."
      },
      {
        "id": "a347c4ed-ccca-3e00-bed0-2da539ab6635",
        "key": "B",
        "text": "With no males left in tank 1, females were potentially large enough to defend territory as males and thus could gain an advantage by becoming male at their current size, whereas females in tank 2 may not have been large enough to outcompete the males in the tank and thus would have greater reproductive success by remaining female."
      },
      {
        "id": "ba60b34b-b824-3c0c-8ec5-e3c06dd59c27",
        "key": "C",
        "text": "Differences in body size among the females in tank 1 became irrelevant to reproductive success once the males were removed, thereby eliminating any advantage to becoming male, whereas the ongoing presence of males in tank 2 made differences in body size among the females in that tank relevant to their reproductive success."
      },
      {
        "id": "49ee0db5-3dea-3515-b38f-303643afa73e",
        "key": "D",
        "text": "Since all males were removed from tank 1, the females in the tank could not reproduce regardless of their size and thus some became male, whereas the presence of males in tank 2 meant that females in that tank could reproduce without first becoming male and thus they remained female."
      }
    ],
    "correct_option_id": "a347c4ed-ccca-3e00-bed0-2da539ab6635",
    "explanation": "Choice B is the best answer because it correctly applies the model presented in Text 1 to explain the different outcomes in the two tanks described in Text 2. Text 1 begins by explaining that fertile female teleost fish will sometimes become fertile males through protogyny. The model, or explanation, of protogyny advanced in Text 1 holds that among female teleost fish, size doesn’t confer any reproductive advantage, but among male teleost fish, “only individuals comparatively large enough to defend territory reproduce”—in other words, there is a direct relationship between relative body size and reproductive success, but only among male fish. Text 1 concludes by saying that, according to this model, individuals can maximize their reproductive success by “staying female when small” (when size has no relevance to reproduction) and only becoming male when they reach a certain size threshold by becoming large enough relative to other male fish to be able to defend territory. In sum, according to the model, whether protogyny is advantageous depends on a female’s body size relative to the males currently present. Text 2 describes an experiment in which fish of “typical size distributions” (meaning, size distributions consistent with Text 1’s note about the tendency of males to be larger than females) were placed in two tanks. Applying Text 1’s model, once the males (that is, the typically larger fish) were removed from tank 1, the remaining females would no longer be at a size disadvantage and could potentially defend territory as males at their current size, making sex change advantageous for some of the fish in tank 1. This would therefore explain the finding that 81 percent of female fish began changing into males. In tank 2, however, the continued presence of larger males meant that on average, females would not be large enough to outcompete the males for territory and would therefore have greater reproductive success by remaining female. In this way, the size-advantage model presented in Text 1 would also account for why no fish changed sex in tank 2.\n\nChoice A is incorrect because it claims that “even small females” could succeed as males once territories were undefended, contradicting Text 1’s emphasis on there being a “critical size threshold” for male reproductive success, wherein only male fish who were sufficiently large to defend territory would have a reproductive advantage. Under this model, small females would have more reproductive success by remaining female than by becoming male and being unable to compete with larger fish for territory. Additionally, this choice’s claim about tank 2—that “only the largest females” could take over territories—implies either that females defend territory (when the model in Text 1 makes no such claim) or that at least some females were sufficiently large to change sex and compete for territory with fish that began the experiment as males, yet the results show that no females in tank 2 did so. Choice C is incorrect. Not only is it based on a flawed understanding of the model presented in Text 1, it flatly contradicts the experimental results summarized in Text 2. While Text 1 clearly states that body size is irrelevant to female reproductive success, choice C states that the presence of males in tank 2 made differences in body size relevant to the females’ reproductive success. This choice also claims that the removal of males from tank 1 eliminated any advantage to becoming male, yet the researchers reported that 81 percent of females in tank 1 began changing sex. Choice D is incorrect because it doesn’t use the model proposed in Text 1 to explain the findings described in Text 2. It is common sense that a certain number of male fish are required for reproduction to occur in tank 1, but the model presented by Text 1 focuses on the individual reproductive benefits of protogyny, not on its potential to benefit the population by maintaining a favorable sex ratio.",
    "source_id": "1917ba9a",
    "source_number": 14,
    "authored_distractors": false
  },
  {
    "id": "f596e04a-0e7e-5a6c-92e5-9c9d241ef670",
    "external_key": "SAT_RW:d4732483",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "HARD",
    "prompt": "Studying late nineteenth- and early twentieth-century artifacts from an agricultural and domestic site in Texas, archaeologist Ayana O. Flewellen found that Black women employed as farm workers utilized hook-and-eye closures to fasten their clothes at the waist, giving themselves a silhouette similar to the one that was popular in contemporary fashion and typically achieved through more restrictive garments such as corsets. Flewellen argues that this sartorial practice shows that these women balanced hegemonic ideals of femininity with the requirements of their physically demanding occupation.\n\nWhich choice best states the main purpose of the text?",
    "options": [
      {
        "id": "8bb70bbb-7afa-3886-b0fc-f3f0a8c3eaa9",
        "key": "A",
        "text": "To describe an unexpected discovery that altered a researcher’s view of how rapidly fashions among Black female farmworkers in late nineteenth- and early twentieth-century Texas changed during the period"
      },
      {
        "id": "e8d0fe7c-4847-3b93-ba5c-ce3269b7508c",
        "key": "B",
        "text": "To discuss research that investigated the ways in which Black female farmworkers in late nineteenth- and early twentieth-century Texas used fashion practices to resist traditional gender ideals"
      },
      {
        "id": "5326a0f4-4005-310a-8c9c-036b8bd4bb92",
        "key": "C",
        "text": "To evaluate a scholarly work that offers explanations for the impact of urban fashion ideals on Black female farmworkers in late nineteenth- and early twentieth-century Texas"
      },
      {
        "id": "b6b6b2f0-0c39-32b2-920e-f725ea79ef9c",
        "key": "D",
        "text": "To summarize the findings of a study that explored factors influencing a fashion practice among Black female farmworkers in late nineteenth- and early twentieth-century Texas"
      }
    ],
    "correct_option_id": "b6b6b2f0-0c39-32b2-920e-f725ea79ef9c",
    "explanation": "Choice D is the best answer. The text provides an overview of a scholarly work discussing the fashion practices of Black female farmworkers in late 19th- and early 20th-century Texas, and how these practices were influenced by both the fashion ideals of the time and the demands of farmwork.\n\nChoice A is incorrect. The text never discusses the rate of fashion change among Black female farmworkers. The text also never categorizes Flewellen’s findings as \"unexpected.\" Choice B is incorrect. The text actually explains that Black female farmworkers were trying to achieve traditional feminine ideals, not resist them. Choice C is incorrect. The text doesn’t evaluate a scholarly work but rather simply describes it. Furthermore, the text is focused on \"agricultural and domestic\" fashion, not urban fashion as this choice suggests.",
    "source_id": "d4732483",
    "source_number": 15,
    "authored_distractors": false
  },
  {
    "id": "0f24d3ac-7918-550e-b2d9-da353c0166e7",
    "external_key": "SAT_RW:d9915c15",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "HARD",
    "prompt": "In 2020, rap artist and professor A.D. Carson published the first peer-reviewed rap album about his experiences with Black masculinity called “i used to love to dream.” Typically in peer review, experts evaluate scholarly articles prior to publication. For Carson’s album, dubbed a “mixtap/e/ssay,” peer review involved both scholars and rap artists. In combining elements of a mixtape album with scholarly essays that connect Carson’s lyrics to historical and contemporary contexts for listeners both inside and outside academia, Carson’s album helped redefine how scholarship is created and shared.\n\nWhich choice best states the main purpose of the text?",
    "options": [
      {
        "id": "6111154f-0993-3340-a5f5-51643a56db98",
        "key": "A",
        "text": "To compare the relative public impact of scholarly articles and albums"
      },
      {
        "id": "a3fa973b-2552-3fa2-8212-cfb012268fea",
        "key": "B",
        "text": "To capture one scholar’s opinion of a new rap album"
      },
      {
        "id": "7702928e-74df-3a7e-b391-c1c1729d541f",
        "key": "C",
        "text": "To explain why a certain rap album is particularly innovative"
      },
      {
        "id": "89888ce0-702c-301f-94b3-6cf15c6ce7cc",
        "key": "D",
        "text": "To describe how each step of the peer review process unfolds"
      }
    ],
    "correct_option_id": "7702928e-74df-3a7e-b391-c1c1729d541f",
    "explanation": "Choice C is the best answer because it best describes the main purpose of the text, which is to explain why a certain rap album is particularly innovative. The text mentions rap artist and professor A.D. Carson, who published \"the first peer-reviewed rap album.\" The text also describes the unusual process of having the work evaluated by both scholars and rap artists before its release, and details how the album combines elements of a mixtape album with elements of scholarly essays. All of these characteristics of the album and the way in which it was developed help to demonstrate the album’s novelty.\n\nChoice A is incorrect because though the text mentions an album that combines elements of scholarly essays and mixtapes, it does not compare the relative public impact of scholarly articles and albums. Choice B is incorrect because the text does not present the opinion of a scholar regarding the rap album. Choice D is incorrect because though the text mentions that the album was peer reviewed, it does not detail the steps of the review.",
    "source_id": "d9915c15",
    "source_number": 16,
    "authored_distractors": false
  },
  {
    "id": "39f76df2-44b4-5660-a72f-908d55358246",
    "external_key": "SAT_RW:e818241b",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "HARD",
    "prompt": "Astronomers are confident that the star Betelgeuse will eventually consume all the helium in its core and explode in a supernova. They are much less confident, however, about when this will happen, since that depends on internal characteristics of Betelgeuse that are largely unknown. Astrophysicist Sarafina El-Badry Nance and colleagues recently investigated whether acoustic waves in the star could be used to determine internal stellar states but concluded that this method could not sufficiently reveal Betelgeuse’s internal characteristics to allow its evolutionary state to be firmly fixed.\n\nWhich choice best describes the function of the second sentence in the overall structure of the text?",
    "options": [
      {
        "id": "227692ba-7211-3a30-8d2a-5b5535b76028",
        "key": "A",
        "text": "It describes a serious limitation of the method used by Nance and colleagues."
      },
      {
        "id": "1bef61c7-62c1-331b-9dfc-b08cd8948043",
        "key": "B",
        "text": "It presents the central finding reported by Nance and colleagues."
      },
      {
        "id": "7de76e43-518d-3e9e-8742-620e3a1953dc",
        "key": "C",
        "text": "It identifies the problem that Nance and colleagues attempted to solve but did not."
      },
      {
        "id": "95e31267-7f0e-32c3-b15b-0a6ce173652a",
        "key": "D",
        "text": "It explains how the work of Nance and colleagues was received by others in the field."
      }
    ],
    "correct_option_id": "7de76e43-518d-3e9e-8742-620e3a1953dc",
    "explanation": "Choice C is the best answer because it best describes how the second sentence functions in the text as a whole. The first sentence establishes something astronomers believe with some certainty: that Betelgeuse will explode in a supernova. The second sentence then introduces a problem: astronomers aren’t certain when Betelgeuse will explode because they don’t have enough information about the star’s internal characteristics. Finally, the third sentence indicates that researcher Sarafina El-Badry Nance and colleagues investigated a possible method of obtaining the necessary information about Betelgeuse’s internal characteristics, though they found that the method wouldn’t be sufficient. Thus, the function of the second sentence is to identify the problem that Nance and colleagues attempted to solve but didn’t.\n\nChoice A is incorrect because the second sentence introduces the general problem Nance and colleagues hoped to solve, not a serious limitation of how Nance and colleagues tried to solve it. It is the third sentence that introduces Nance and colleagues, but no serious limitation of their approach to studying a method of determining internal stellar states is described. Choice B is incorrect because the second sentence introduces the general problem Nance and colleagues hoped to solve, not the central finding they ultimately reported. It is the third sentence that presents Nance and colleagues’ conclusion that a potential method for determining internal stellar states would be insufficient. Choice D is incorrect because the second sentence doesn’t indicate how other astronomers or astrophysicists responded to the work done by Nance and colleagues; the text doesn’t address this information at all.",
    "source_id": "e818241b",
    "source_number": 17,
    "authored_distractors": false
  },
  {
    "id": "3390c106-7a1e-56af-8774-baecd457cef3",
    "external_key": "SAT_RW:d5ad34f0",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "HARD",
    "prompt": "The results of randomized clinical trials testing the efficacy of common medical interventions sometimes fail to ______ conclusions that practitioners reach based on their real-world observations of patients. While there are several possible reasons for this, one is that practitioners may overlook confounding variables that account for the results they attribute to the interventions in question.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "b648f418-5680-3b21-bfab-1ea5e3833938",
        "key": "A",
        "text": "circumvent"
      },
      {
        "id": "4e68ddce-b231-3437-b682-3d9db851e9a7",
        "key": "B",
        "text": "corroborate"
      },
      {
        "id": "604be4cf-253a-3a92-b23b-35c00be1be56",
        "key": "C",
        "text": "disseminate"
      },
      {
        "id": "7e406c02-bf24-3f66-820c-d2b8ff3307b3",
        "key": "D",
        "text": "implement"
      }
    ],
    "correct_option_id": "4e68ddce-b231-3437-b682-3d9db851e9a7",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion of a relationship between the results of randomized clinical tests of how effective common medical interventions are and the conclusions practitioners reach about such interventions in real-world settings. In this context, \"corroborate\" means confirm or support with evidence. The text indicates that one possible explanation for the relationship being discussed is that practitioners may overlook confounding variables—that is, additional factors other than the medical interventions being investigated that affect the observed outcomes. This means that practitioners may assume that an outcome is the direct result of a medical intervention when it is actually the result of a combination of factors. Clinical trials take steps to rule out factors other than the one being studied, so if those extra factors are actually having an effect on real-world outcomes, the trials are likely to produce conclusions different from those practitioners reach in their real-world observations. In other words, clinical trials may fail to corroborate practitioners’ conclusions.\n\nChoice A is incorrect because it wouldn’t make sense to say that the results of clinical trials could \"circumvent,\" or find a way around or bypass, conclusions practitioners reach in real-world scenarios with patients; it’s possible that researchers conducting the trials might avoid engaging with practitioners’ conclusions, but findings from a study can’t choose to get around something. Choice C is incorrect because it wouldn’t make sense to say that the results of clinical trials could \"disseminate,\" or spread widely, conclusions practitioners reach in real-world scenarios with patients; the researchers conducting the trials might choose to draw attention to practitioners’ conclusions, but findings from a study can’t spread anything. Choice D is incorrect because it wouldn’t make sense to say that the results of clinical trials could \"implement,\" or put into effect, conclusions practitioners reach in real-world scenarios with patients; the researchers conducting the trials might consider practitioners’ conclusions, but findings from a study can’t put anything into effect.",
    "source_id": "d5ad34f0",
    "source_number": 18,
    "authored_distractors": false
  },
  {
    "id": "915aed28-046d-5cf7-a686-81592da96c2f",
    "external_key": "SAT_RW:6c086e70",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "HARD",
    "prompt": "Businesses typically try to promote themselves, but research by Michael Luca, Abhishek Nagaraj, and Gauri Subramani suggests that some do not ______ their marketing. The researchers studied restaurants in Texas and found that those listed on a popular review website (which can be done at no cost) had revenue increases of 5 percent on average, but 33 percent of restaurants studied never listed on the site.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "f05e4a54-7294-3be3-b680-aaf6578a1bb0",
        "key": "A",
        "text": "adorn"
      },
      {
        "id": "aced6586-6ee0-330a-a36f-43394ba8e22d",
        "key": "B",
        "text": "optimize"
      },
      {
        "id": "c5a6e27c-7c3e-3e9d-bdd9-3cacf902c8f1",
        "key": "C",
        "text": "endorse"
      },
      {
        "id": "fbdce6cb-796b-3d8f-92bb-8bfaab091055",
        "key": "D",
        "text": "counteract"
      }
    ],
    "correct_option_id": "aced6586-6ee0-330a-a36f-43394ba8e22d",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion of business marketing practices. In this context, \"optimize\" means make the most effective possible use of available opportunities. The text indicates that though businesses typically try to promote themselves, they don’t always make use of effective tools for doing so, pointing to research showing that 33 percent of restaurants failed to use a free listing service that increased revenue by 5 percent on average for restaurants that did use the service. The text therefore suggests that by foregoing a free and effective marketing tool, some businesses aren’t making the best use of, or optimizing, marketing opportunities.\n\nChoice A is incorrect because in this context, \"adorn\" would mean decorate or enhance the appearance of, and there’s nothing in the text to suggest that by failing to use a free and effective promotional tool, some businesses aren’t enhancing the appearance of their own marketing. The example in the text illustrates that some businesses aren’t utilizing an effective marketing opportunity, not that they aren’t improving the appearance of their marketing. Choice C is incorrect because in this context, \"endorse\" would mean openly approve or recommend, and the text’s discussion of the fact that some businesses have overlooked an effective marketing tool doesn’t support the idea that those businesses therefore don’t approve of their own marketing. Choice D is incorrect because in this context, saying that businesses don’t \"counteract\" their marketing would suggest that they don’t actively undermine it or make it ineffective. The text begins by stating that businesses typically try to promote themselves but then continues to imply that some businesses fail to take advantage of good opportunities to do so, citing the example of businesses that failed to use a free and effective marketing tool. Though it’s possible that those businesses that did use the site therefore didn’t unintentionally counteract their own marketing, the first sentence conveys that the text’s focus is on things that some businesses do and that some businesses don’t do when trying to promote themselves, and it wouldn’t make sense to say that any businesses would actively try to undermine their own marketing in pursuit of that goal.",
    "source_id": "6c086e70",
    "source_number": 19,
    "authored_distractors": false
  },
  {
    "id": "a960739f-564a-5393-974c-39ada7f792ca",
    "external_key": "SAT_RW:6c9f1727",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "HARD",
    "prompt": "One popular theory of the origin of the Moon, the “big whack,” posits that a protoplanet called Theia collided with Earth, flinging debris into orbit that eventually coalesced into the Moon. Until recently, Theia was ______, but researcher Qian Yuan and colleagues now claim to have identified pieces of the protoplanet in the lowermost section of Earth’s mantle.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "4f48e29d-f249-31fc-802d-f21600b1a39b",
        "key": "A",
        "text": "desultory"
      },
      {
        "id": "c4eea9ac-4dfb-3fdb-a535-a3a909eed930",
        "key": "B",
        "text": "spurious"
      },
      {
        "id": "92f3e062-7134-359f-b5cf-1952101af88f",
        "key": "C",
        "text": "veritable"
      },
      {
        "id": "8df23bc7-f962-3063-9398-2820151de035",
        "key": "D",
        "text": "notional"
      }
    ],
    "correct_option_id": "8df23bc7-f962-3063-9398-2820151de035",
    "explanation": "Choice D is the best answer because it most logically completes the text’s discussion of Theia and the origin of the Moon. In this context, \"notional\" means theoretical or only an idea. The text indicates that although something was once true of Theia, the protoplanet one theory holds collided with Earth and created debris that became the Moon, researchers now claim to have identified pieces of it deep in Earth’s mantle. In other words, having direct evidence of Theia is a new development. This context suggests that before evidence was found, Theia was only theoretical—that is, that it was notional.\n\nChoice A is incorrect because the text doesn’t suggest that Theia, a protoplanet, was \"desultory,\" which in this context would mean moving away from the matter at hand; indeed, the text focuses on the \"big whack\" theory of the origin of the Moon and indicates that Theia is a central part of that theory. Choice B is incorrect because the text makes the point that something was true of Theia until recently and suggests that this has changed now that researchers believe they have found pieces of the protoplanet deep in Earth’s mantle. It wouldn’t make sense to say that Theia was actually \"spurious,\" or false, until researchers found direct evidence of the protoplanet. (Although Theia’s existence might not have been certain, it would not have been false simply because there was no evidence of it.) Choice C is incorrect because the text makes the point that something was true of Theia until recently and suggests that this has changed now that researchers believe they have found pieces of the protoplanet deep in Earth’s mantle. It wouldn’t make sense to say that Theia was \"veritable,\" or real, before researchers found direct evidence of its existence: the evidence would instead confirm that Theia was real.",
    "source_id": "6c9f1727",
    "source_number": 20,
    "authored_distractors": false
  },
  {
    "id": "c10d66d4-0200-5c57-9f70-2e4d446a9cf2",
    "external_key": "SAT_RW:2c61e0b9",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "HARD",
    "prompt": "While researching a topic, a student has taken the following notes:\n- British musicians John Lennon and Paul McCartney shared writing credit for numerous Beatles songs.\n- Many Lennon-McCartney songs were actually written by either Lennon or McCartney, not by both.\n- The exact authorship of specific parts of many Beatles songs, such as the verse for “In My Life,” is disputed.\n- Mark Glickman, Jason Brown, and Ryan Song used statistical methods to analyze the musical content of Beatles songs.\n- They concluded that there is 18.9% probability that McCartney wrote the verse for “In My Life,” stating that the verse is “consistent with Lennon’s songwriting style.”\n\nThe student wants to make a generalization about the kind of study conducted by Glickman, Brown, and Song. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "9a186691-1390-3e5b-baaf-d9fd67b8310e",
        "key": "A",
        "text": "Based on statistical analysis, Glickman, Brown, and Song claim that John Lennon wrote the verse of “In My Life.”"
      },
      {
        "id": "5a85820d-d8c2-380e-a704-57c5c7fc8aff",
        "key": "B",
        "text": "There is only an 18.9% probability that Paul McCartney wrote the verse for “In My Life”; John Lennon is the more likely author."
      },
      {
        "id": "a990c5ad-9513-3794-8217-3c5c4998a5ea",
        "key": "C",
        "text": "It is likely that John Lennon, not Paul McCartney, wrote the verse for “In My Life.”"
      },
      {
        "id": "83297388-a472-3e80-9c9a-10335eeccdf3",
        "key": "D",
        "text": "Researchers have used statistical methods to address questions of authorship within the field of music."
      }
    ],
    "correct_option_id": "83297388-a472-3e80-9c9a-10335eeccdf3",
    "explanation": "Choice D is the best answer. The sentence uses information from the notes to make a generalization about the kind of study Glickman, Brown, and Song conducted. Specifically, the sentence indicates that the study was of a kind that used statistical methods to address questions of authorship within the field of music.\n\nChoice A is incorrect because the sentence summarizes the methodology and findings of a particular analysis of a single song; it doesn’t make a generalization about the kind of study conducted. Choice B is incorrect because the sentence mentions the data and conclusion of a particular analysis of a single song; it doesn’t make a generalization about the kind of study conducted. Choice C is incorrect because the sentence focuses on a specific conclusion from a particular analysis of a single song; it doesn’t make a generalization about the kind of study conducted.",
    "source_id": "2c61e0b9",
    "source_number": 21,
    "authored_distractors": false
  },
  {
    "id": "7d3a83a8-71de-5857-ae92-c9143827a268",
    "external_key": "SAT_RW:9dc4e640",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "HARD",
    "prompt": "The mineral mtorolite is most commonly found in Zimbabwe. Mtorolite is cryptocrystalline, meaning that its crystalline structure is so fine that the individual crystals cannot be distinguished by the naked eye or even under a microscope. The crystals in microcrystalline minerals are also not visible to the naked eye; ______ they can usually be seen under a microscope.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "2c2f4de5-ad23-3ef8-9158-ceb03eb01796",
        "key": "A",
        "text": "thus,"
      },
      {
        "id": "2c11c4ca-b19b-375f-b5e1-59d615c10034",
        "key": "B",
        "text": "for example,"
      },
      {
        "id": "0b688f6d-9122-3249-8369-c559abe25abf",
        "key": "C",
        "text": "that said,"
      },
      {
        "id": "0d0612b5-39ba-3d49-b0b9-1f2e6bd35117",
        "key": "D",
        "text": "similarly,"
      }
    ],
    "correct_option_id": "0b688f6d-9122-3249-8369-c559abe25abf",
    "explanation": "Choice C is the best answer because \"that said\" logically signals that the information that follows—that the crystals of microcrystalline minerals can be seen with a microscope—is an exception to the previous information about the crystalline structure of minerals not being visible under a microscope.\n\nChoice A is incorrect because \"thus\" illogically signals that the information that follows is a direct result or consequence of the fact that the crystals of microcrystalline minerals aren’t visible to the naked eye. Instead, the fact that they can be seen under a microscope is an exception to the previous information about crystalline minerals. Choice B is incorrect because \"for example\" illogically signals that the information that follows exemplifies the fact that the crystals of microcrystalline minerals aren’t visible to the naked eye. Instead, the fact that they can be seen under a microscope is an exception to the previous information about crystalline minerals. Choice D is incorrect because \"similarly\" illogically signals that the information that follows is similar or comparable to the fact that the crystals of microcrystalline minerals aren’t visible to the naked eye. Instead, the fact that they can be seen under a microscope is an exception to the previous information about crystalline minerals.",
    "source_id": "9dc4e640",
    "source_number": 22,
    "authored_distractors": false
  },
  {
    "id": "71df5f63-f4f7-5624-b7e4-7e328a0a7bbb",
    "external_key": "SAT_RW:f5149550",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "HARD",
    "prompt": "A staunch supporter of women’s voting rights, Wilhelmina Kekelaokalaninui Widemann Dowsett sought to coordinate the efforts of suffragists in her native Hawai‘i. ______ in 1912, she founded the National Women’s Equal Suffrage Association of Hawai‘i, an organization that lobbied for women’s voting rights in the US territory.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "c692acf6-b27a-3518-94aa-ae98cd130713",
        "key": "A",
        "text": "In other words,"
      },
      {
        "id": "c5db5974-d447-3145-8c6a-63bf54139550",
        "key": "B",
        "text": "Conversely,"
      },
      {
        "id": "74329185-1ae1-3bb9-9a39-7a0e087d24ba",
        "key": "C",
        "text": "To that end,"
      },
      {
        "id": "a7891f34-bc4c-34c2-bf3c-5198fd134722",
        "key": "D",
        "text": "Alternatively,"
      }
    ],
    "correct_option_id": "74329185-1ae1-3bb9-9a39-7a0e087d24ba",
    "explanation": "Choice C is the best answer. “To that end” logically signals that the information in this sentence—that Dowsett founded the National Women’s Equal Suffrage Association of Hawai‘i—describes an action Dowsett took to achieve the goal stated in the previous sentence: to coordinate the efforts of suffragists in Hawai‘i.\n\nChoice A is incorrect because “in other words” illogically signals that the information in this sentence about Dowsett founding a women’s suffrage association is a paraphrase or restatement of the previous information about Dowsett seeking to coordinate suffragists’ efforts. Instead, the sentence describes a specific action Dowsett took to achieve this goal. Choice B is incorrect because “conversely” illogically signals that the information in this sentence about Dowsett founding a women’s suffrage association contrasts with the previous information about Dowsett seeking to coordinate suffragists’ efforts. Instead, the sentence describes a specific action Dowsett took to achieve this goal. Choice D is incorrect because “alternatively” illogically signals that the information in this sentence about Dowsett founding a women’s suffrage association presents an alternative to her seeking to coordinate suffragists’ efforts. Instead, the sentence describes a specific action Dowsett took to achieve this goal.",
    "source_id": "f5149550",
    "source_number": 23,
    "authored_distractors": false
  },
  {
    "id": "096e84fc-4c88-596a-81e2-4bbc96104cd4",
    "external_key": "SAT_RW:af88c47a",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "HARD",
    "prompt": "While researching a topic, a student has taken the following notes:\n- Freddie Wong (born 1985) is a director and special effects artist from the United States.\n- He is best known for the action-comedy web series *Video Game High School* (*VGHS*).\n- *VGHS* premiered in 2012 on RocketJump, a YouTube channel that Wong cocreated.\n- The series was celebrated for its inventive video game–centric world and high-quality special effects.\n- *VGHS* was nominated for a Producers Guild Award for Outstanding Digital Series.\n\nThe student wants to begin a narrative about Wong’s award-nominated web series. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "ba601d96-8df8-339b-8775-ffceed91976e",
        "key": "A",
        "text": "In 2012, director and visual effects artist Freddie Wong launched a new action-comedy web series: *Video Game High School*."
      },
      {
        "id": "b5bcc1a2-d56c-3a83-9e58-fe53232ec6df",
        "key": "B",
        "text": "*Video Game High School* was celebrated for its inventive video game–centric world and high-quality special effects, and it was nominated for a Producer’s Guild Award for Outstanding Digital Series."
      },
      {
        "id": "e82b459d-8cea-37ee-a7b6-6dcba0c2a678",
        "key": "C",
        "text": "Wong, cocreator of the YouTube channel RocketJump, would go on to see his web series be nominated for a Producers Guild Award."
      },
      {
        "id": "5fbcd9e0-a98c-36de-b25a-c9306c47176b",
        "key": "D",
        "text": "In 2012, *Video Game High School* premiered on RocketJump; it would later be nominated for an award."
      }
    ],
    "correct_option_id": "ba601d96-8df8-339b-8775-ffceed91976e",
    "explanation": "Choice A is the best answer. This choice introduces Wong and *VGHS* in an active and specific way, as if to an audience unfamiliar with the series. It also sets up the time and genre of the web series, which are useful ways to introduce the series of events in a narrative.\n\nChoice B is incorrect. This choice isn’t suited for beginning a narrative. A narrative is a story that follows a sequence of events and creates interest and suspense for the reader. This choice jumps to the end, explaining the success of *VGHS* without explaining what it is. Choice C is incorrect. This choice isn’t suited for beginning a narrative. It doesn’t actually introduce the web series by name. It just jumps to later in the story without sufficient explanation. Choice D is incorrect. This choice is not very effective for beginning a narrative. It doesn’t explain what *VGHS* is, and it doesn’t mention Wong.",
    "source_id": "af88c47a",
    "source_number": 24,
    "authored_distractors": false
  },
  {
    "id": "687f40af-0f39-5e43-a140-5e5814e1d60a",
    "external_key": "SAT_RW:a266d876",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "HARD",
    "prompt": "Upper-atmospheric jets—phenomena whereby electrical discharges cause narrow cones of blue light to briefly burst upward from the tops of thunderclouds—have been observed reaching the ionosphere. The extreme altitudes involved (the ionosphere begins about 80 km above Earth) mark these gigantic jets as outliers; ______ the majority of jets reach heights of only 20 to 50 km.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "e5c0b970-b631-35c4-8d21-8b8933ff1648",
        "key": "A",
        "text": "nevertheless,"
      },
      {
        "id": "1de7a33a-e2f8-3032-8aa3-cde2132452d3",
        "key": "B",
        "text": "consequently,"
      },
      {
        "id": "18ee2399-4dd0-3223-9abd-87ab174b49a3",
        "key": "C",
        "text": "indeed,"
      },
      {
        "id": "1ffa4b95-0da1-3a84-aa60-81e26a7d553f",
        "key": "D",
        "text": "in addition,"
      }
    ],
    "correct_option_id": "18ee2399-4dd0-3223-9abd-87ab174b49a3",
    "explanation": "Choice C is the best answer. “Indeed” logically signals that the information that follows—that the majority of jets reach heights of only 20 to 50 km—offers additional emphasis in support of the previous claim that jets reaching the ionosphere (about 80 km above Earth) are outliers.\n\nChoice A is incorrect because “nevertheless” illogically signals that the information about most jets reaching heights of only 20 to 50 km contrasts with the previous claim that jets reaching the ionosphere are outliers. Instead, it provides additional emphasis in support of that claim. Choice B is incorrect because “consequently” illogically signals that the information about most jets reaching heights of only 20 to 50 km is a consequence, or result, of some jets being outliers. Instead, it offers additional emphasis in support of the claim that jets reaching the ionosphere are outliers. Choice D is incorrect because “in addition” illogically signals that the information about most jets reaching heights of only 20 to 50 km merely adds to the previous claim that jets reaching the ionosphere are considered outliers. Instead, it provides additional emphasis in support of that claim.",
    "source_id": "a266d876",
    "source_number": 25,
    "authored_distractors": false
  },
  {
    "id": "b163aa1d-af82-51ea-bfee-6d61f4ea125d",
    "external_key": "SAT_RW:9551ef8b",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "HARD",
    "prompt": "While researching a topic, a student has taken the following notes:\n- The magnificent frigatebird (*fregata magnificens*) is a species of seabird that feeds mainly on fish, tuna, squid, and other small sea animals.\n- It is unusual among seabirds in that it doesn’t dive into the water for prey.\n- One way it acquires food is by using its hook-tipped bill to snatch prey from the surface of the water.\n- Another way it acquires food is by taking it from weaker birds by force.\n- This behavior is known as kleptoparasitism.\n\nThe student wants to emphasize a similarity between the two ways a magnificent frigatebird acquires food. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "7d66b69d-a0e3-3598-b4fc-7fa8e5cb2482",
        "key": "A",
        "text": "A magnificent frigatebird never dives into the water, instead using its hook-tipped bill to snatch prey from the surface."
      },
      {
        "id": "182222eb-aad4-3465-9503-41018ceda364",
        "key": "B",
        "text": "Neither of a magnificent frigatebird’s two ways of acquiring food requires the bird to dive into the water."
      },
      {
        "id": "25339f19-808b-3296-8974-f5fcb5281faa",
        "key": "C",
        "text": "Of the magnificent frigatebird’s two ways of acquiring food, only one is known as kleptoparasitism."
      },
      {
        "id": "19a362d9-cb1a-38a7-83f9-44e5201348d7",
        "key": "D",
        "text": "In addition to snatching prey from the water with its hook-tipped bill, a magnificent frigatebird takes food from other birds by force."
      }
    ],
    "correct_option_id": "182222eb-aad4-3465-9503-41018ceda364",
    "explanation": "Choice B is the best answer. The sentence emphasizes a similarity between the two ways a magnificent frigatebird acquires food, noting that neither way requires the seabird to dive into the water.\n\nChoice A is incorrect. The sentence describes how a magnificent frigatebird captures prey without diving into water; it doesn’t emphasize a similarity between the two ways the seabird acquires food. Choice C is incorrect. The sentence notes the term used to describe one of the two ways that magnificent frigatebirds acquire food; it doesn’t emphasize a similarity between the two ways. Choice D is incorrect. The sentence describes the two ways that a magnificent frigatebird acquires food; it doesn’t emphasize a similarity between the two ways.",
    "source_id": "9551ef8b",
    "source_number": 26,
    "authored_distractors": false
  },
  {
    "id": "ddfe598c-671d-5c00-8622-22dc3d3bcf14",
    "external_key": "SAT_RW:9502ec65",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "HARD",
    "prompt": "When soil becomes contaminated by toxic metals, it can be removed from the ground and disposed of in a landfill. ______ contaminated soil can be detoxified via phytoremediation: plants that can withstand high concentrations of metals absorb the pollutants and store them in their shoots, which are then cut off and safely disposed of, preserving the health of the plants.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "3ce66c13-c8ce-3601-9b0d-221a3370242a",
        "key": "A",
        "text": "Alternatively,"
      },
      {
        "id": "c6522834-caca-3fa4-a2fc-a2d7dcb1bf0e",
        "key": "B",
        "text": "Specifically,"
      },
      {
        "id": "7fffe408-747c-3948-9cfc-21ddde17cd26",
        "key": "C",
        "text": "For example,"
      },
      {
        "id": "37a374fa-9336-37ac-b738-44d6f8182a29",
        "key": "D",
        "text": "As a result,"
      }
    ],
    "correct_option_id": "3ce66c13-c8ce-3601-9b0d-221a3370242a",
    "explanation": "Choice A is the best answer. “Alternatively” logically signals that the soil decontamination method described in this sentence—removing toxic metals from the soil via phytoremediation—offers an alternative to the previously described method (removing the contaminated soil from the ground).\n\nChoice B is incorrect because “specifically” illogically signals that the soil decontamination method described in this sentence specifies or elaborates on an aspect of the previously described method (removing the contaminated soil from the ground). Instead, phytoremediation is an alternative to that method. Choice C is incorrect because “for example” illogically signals that the soil decontamination method described in this sentence is an example of the previously described method (removing the contaminated soil from the ground). Instead, phytoremediation is an alternative to that method. Choice D is incorrect because “as a result” illogically signals that the soil decontamination method described in this sentence is a result or consequence of the previously described method (removing the contaminated soil from the ground). Instead, phytoremediation is an alternative to that method.",
    "source_id": "9502ec65",
    "source_number": 27,
    "authored_distractors": false
  },
  {
    "id": "6269cac1-c31e-5508-9945-348c242b1d06",
    "external_key": "SAT_RW:be3363dd",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "HARD",
    "prompt": "While researching a topic, a student has taken the following notes:\n- Suzanne K. Birner led a study analyzing rocks on the seafloor to better understand the history of Earth’s mantle.\n- Rock samples were collected from two seafloor ridges.\n- The researchers determined the samples’ period of formation (the Archean eon) and oxidation level (extremely low).\n- High temperatures in the Archean likely caused the rocks’ low oxidation.\n- Birner’s team suggests the oxidation of Earth’s mantle has remained stable over time, contrary to previous theories.\n- The findings help explain the unique conditions that allowed life to develop on Earth.\n\nThe student wants to present the study’s research methods. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "1c5114b4-1385-309d-9a9c-d084b3d6754d",
        "key": "A",
        "text": "Birner led a study to better understand the history of Earth’s mantle and explain the conditions that allowed life to develop."
      },
      {
        "id": "4699b82e-15cd-3433-bee3-db40db6a82a9",
        "key": "B",
        "text": "To further analyze the origins of Earth’s unique conditions, researchers focused on rocks from the Archean eon, when Earth’s temperatures were extremely high."
      },
      {
        "id": "5bd28993-8542-32e1-bdc1-d00f21b8d519",
        "key": "C",
        "text": "By studying these ancient rocks, the team aimed to challenge previous theories about changes in Earth’s mantle over time."
      },
      {
        "id": "15f47618-0757-3bfb-b432-888e5bf3a615",
        "key": "D",
        "text": "Birner’s team analyzed the age and oxidation levels of rock samples collected from two seafloor ridges."
      }
    ],
    "correct_option_id": "15f47618-0757-3bfb-b432-888e5bf3a615",
    "explanation": "Choice D is the best answer. The sentence presents the study’s research methods, explaining that Birner’s team analyzed the age and oxidation levels of rock samples collected from two seafloor ridges.\n\nChoice A is incorrect. The sentence describes the purpose of the study (to understand the history of Earth’s mantle and explain conditions for life); it doesn’t present the study’s research methods. Choice B is incorrect. The sentence notes the study’s focus on rocks from the Archean eon and a characteristic of the eon; it doesn’t present the study’s research methods. Choice C is incorrect. The sentence indicates the goal of the study (to challenge previous theories); it doesn’t present the study’s research methods.",
    "source_id": "be3363dd",
    "source_number": 28,
    "authored_distractors": false
  },
  {
    "id": "62b0fa1b-d7d3-5d30-8a65-52a97e6580f3",
    "external_key": "SAT_RW:459df2ba",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "HARD",
    "prompt": "While researching a topic, a student has taken the following notes:\n- Modularity of mind is the notion that the mind is at least partly composed of innate neural structures (modules) that perform fast, necessary tasks.\n- 1983: cognitive scientist Jerry A. Fodor hypothesized that low-level cognitive systems (e.g., perception, language) are modular.\n- In Fodorian modularity, high-level systems (e.g., reasoning) are not modular.\n- 2003: cognitive scientist Peter Carruthers proposed the massive modularity hypothesis (MMH).\n- MMH expands modularity to include all cognitive systems.\n\nThe student wants to compare Fodor’s hypothesis with Carruthers’s. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "500dc895-19b7-3324-8421-d99cde9856d9",
        "key": "A",
        "text": "In considering some but not all cognitive systems modular, Fodorian modularity is not as expansive in its definition of modularity as MMH is."
      },
      {
        "id": "2a9395be-ee9b-3261-9676-dec6dc4282d2",
        "key": "B",
        "text": "Following Fodor’s 1983 hypothesis, Carruthers proposed that modularity of mind includes all cognitive systems."
      },
      {
        "id": "069f43f2-029f-3347-bd2d-35a9a10c0c5f",
        "key": "C",
        "text": "The hypotheses of Fodor and Carruthers differ in whether they consider low-level cognitive systems, such as perception and language, modular."
      },
      {
        "id": "b33abca9-1b29-3e81-b101-7af3e5713f76",
        "key": "D",
        "text": "In 2003, Carruthers proposed the massive modularity hypothesis, disagreeing with Fodor’s earlier hypothesis that the mind is composed of innate neural structures."
      }
    ],
    "correct_option_id": "500dc895-19b7-3324-8421-d99cde9856d9",
    "explanation": "Choice A is the best answer. The sentence compares Fodor’s hypothesis with Carruthers’s, noting that because Fodorian modularity considers some but not all cognitive systems modular, it is not as expansive in its definition of modularity as Carruthers’s MMH, which includes all cognitive systems.\n\nChoice B is incorrect. The sentence describes Carruthers’s hypothesis—that modularity of mind includes all cognitive systems—but indicates only that this hypothesis followed Fodor’s 1983 hypothesis rather than making a comparison between the hypotheses. Choice C is incorrect. The sentence misrepresents a difference between Fodor’s and Carruthers’s hypotheses. According to the information in the notes, both Fodor and Carruthers consider low-level cognitive systems modular, and their difference lies in whether they also consider high-level systems modular. Choice D is incorrect. The sentence misrepresents a difference between Fodor’s and Carruthers’s hypotheses. According to the information in the notes, both Fodor and Carruthers consider the mind to be at least partly composed of innate neural structures (modules). Their difference lies in whether they consider high-level systems modular.",
    "source_id": "459df2ba",
    "source_number": 29,
    "authored_distractors": false
  },
  {
    "id": "ff838954-4981-55bb-a29a-1772bdf96f96",
    "external_key": "SAT_RW:8e9e473d",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "HARD",
    "prompt": "While researching a topic, a student has taken the following notes:\n- A 2024 study analyzed the facial expressions of wolves and domestic dogs.\n- In the study, facial expressions were coded under 46 different facial actions.\n- The “ears rotator” facial action is seen in wolves.\n- Dog breeds with erect (wolf-like) ears can produce the “ears rotator” facial action.\n- Dog breeds with flopped or semi-flopped (non-wolf-like) ears cannot produce the “ears rotator” facial action.\n\nThe student wants to compare dog breeds with wolf-like ears to dog breeds with non-wolf-like ears. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "a7f8bc8a-1067-3e10-a033-eea519cb79b8",
        "key": "A",
        "text": "In a 2024 study, dog breeds with non-wolf-like ears were able to produce the same facial movements that wolves could."
      },
      {
        "id": "f0b60bab-2488-3be2-8d47-3532e81a501f",
        "key": "B",
        "text": "One difference between dog breeds with wolf-like ears and dog breeds without them is that wolf-like breeds cannot produce the “ears rotator” facial action."
      },
      {
        "id": "fc77b199-b995-3b4b-ab07-dbd077fe7575",
        "key": "C",
        "text": "Non-wolf-like ears are flopped or semi-flopped, but wolf-like ears are different: they are erect and can produce the “ears rotator” facial action."
      },
      {
        "id": "efa4bf73-5041-3e43-b923-9b887e7f22b0",
        "key": "D",
        "text": "Like wolves, dog breeds with erect ears can produce the “ears rotator” facial action, while those with flopped or semi-flopped ears cannot."
      }
    ],
    "correct_option_id": "efa4bf73-5041-3e43-b923-9b887e7f22b0",
    "explanation": "Choice D is the best answer. The sentence compares dog breeds with wolf-like (erect) and non-wolf-like (flopped or semi-flopped) ears, noting that breeds with erect ears are able to produce the same “ears rotator” facial action as wolves, while breeds with flopped or semi-flopped ears cannot.\n\nChoice A is incorrect. The sentence compares dog breeds with non-wolf-like ears to wolves, not to other dog breeds. It also misrepresents information from the notes: breeds with non-wolf-like ears cannot produce the “ears rotator” facial action. Choice B is incorrect. While the sentence appears to compare dog breeds with wolf-like and non-wolf-like ears, it misrepresents information from the notes: breeds with wolf-like ears can produce the “ears rotator” facial action. Choice C is incorrect. While the sentence compares the physical characteristics of the two ear types, it doesn’t compare the dog breeds that have these ear types.",
    "source_id": "8e9e473d",
    "source_number": 30,
    "authored_distractors": false
  },
  {
    "id": "7f84d276-9fb1-5e1a-8897-f1bb80edda87",
    "external_key": "SAT_RW:16740ab4",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "HARD",
    "prompt": "At the Chicxulub asteroid impact crater in Mexico, the presence of many fossilized microbacteria, which seem to have thrived there despite the extreme heat that persisted after the Chicxulub impact, ______ claims that bacteria are among the planet’s most resilient organisms.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "ee6cfee0-e3ca-3c96-936e-168cecdc088a",
        "key": "A",
        "text": "have reinforced"
      },
      {
        "id": "4b58e4cf-260c-3e2c-9953-e0ff8c790933",
        "key": "B",
        "text": "reinforces"
      },
      {
        "id": "c775c34b-2c36-321a-bb83-9420f0bfd7c8",
        "key": "C",
        "text": "are reinforcing"
      },
      {
        "id": "338f557c-0e59-337c-9341-b629f2811abf",
        "key": "D",
        "text": "reinforce"
      }
    ],
    "correct_option_id": "4b58e4cf-260c-3e2c-9953-e0ff8c790933",
    "explanation": "Choice B is the best answer. The convention being tested is subject-verb agreement. The singular verb “reinforces” agrees in number with the singular subject “the presence.”\n\nChoice A is incorrect because the plural verb “have reinforced” doesn’t agree in number with the singular subject “the presence.” Choice C is incorrect because the plural verb “are reinforcing” doesn’t agree in number with the singular subject “the presence.” Choice D is incorrect because the plural verb “reinforce” doesn’t agree in number with the singular subject “the presence.”",
    "source_id": "16740ab4",
    "source_number": 31,
    "authored_distractors": false
  },
  {
    "id": "ba23fc79-234a-57b6-86f4-ca595188d3d4",
    "external_key": "SAT_RW:f78997cf",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "HARD",
    "prompt": "Recent analysis of 32532 Thereus—an outer solar system object orbiting the Sun between Jupiter and Saturn—has determined its color to be gray, suggesting an icy composition. Such interpretations are ultimately ______ the object’s gray coloration may be an incidental effect of radiation, solar wind, or collisions with other objects rather than evidence of its physical makeup.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "29330ae1-90f5-3868-bc85-a83db6d87946",
        "key": "A",
        "text": "speculative, though"
      },
      {
        "id": "033781a1-e5df-38f4-8f5b-add3f18cda2d",
        "key": "B",
        "text": "speculative, though;"
      },
      {
        "id": "7a2dd645-a53b-36f6-b490-55ed7e59e50e",
        "key": "C",
        "text": "speculative; though"
      },
      {
        "id": "e53a326c-d113-3cb7-8980-6d0b0651a2eb",
        "key": "D",
        "text": "speculative, though,"
      }
    ],
    "correct_option_id": "033781a1-e5df-38f4-8f5b-add3f18cda2d",
    "explanation": "Choice B is the best answer. The convention being tested is the use of punctuation in a sentence. This choice correctly uses a comma to separate the supplementary adverb \"though\" from the preceding main clause (\"Such interpretations are ultimately speculative\") and uses a semicolon to join the next main clause (\"the object’s...makeup\") to the rest of the sentence. Further, placing the semicolon after \"though\" indicates that the information in the preceding main clause (interpretations of an outer solar system object’s composition based on its color are ultimately speculative) is a qualification of the information in the previous sentence (the composition of an outer solar system object is suggested by its color).\n\nChoice A is incorrect because it fails to mark the boundary between the two main clauses with appropriate punctuation. Choice C is incorrect because placing the semicolon after \"speculative\" illogically indicates that the information in the next main clause (\"the object’s...makeup\") is a qualification of the information in the previous clause (\"Such...speculative\"). Choice D is incorrect because it results in a comma splice. Commas can’t be used in this way to punctuate a supplementary word or phrase between two main clauses.",
    "source_id": "f78997cf",
    "source_number": 32,
    "authored_distractors": false
  },
  {
    "id": "d0f45624-6f1b-5707-a293-ee725987a226",
    "external_key": "SAT_RW:f0864217",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "HARD",
    "prompt": "*Rabinal Achí* is a precolonial Maya dance drama performed annually in Rabinal, a town in the Guatemalan highlands. Based on events that occurred when Rabinal was a city-state ruled by a king, ______ had once been an ally of the king but was later captured while leading an invading force against him.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "2a3d269f-1fb0-3abd-8904-f3f48b16d463",
        "key": "A",
        "text": "*Rabinal Achí* tells the story of K’iche’ Achí, a military leader who"
      },
      {
        "id": "307ef745-1102-378f-aac0-d51e12d21af1",
        "key": "B",
        "text": "K’iche’ Achí, the military leader in the story of *Rabinal Achí*,"
      },
      {
        "id": "bb96fa46-9299-35c5-914d-675f950f715c",
        "key": "C",
        "text": "the military leader whose story is told in *Rabinal Achí*, K’iche’ Achí,"
      },
      {
        "id": "d16e7804-2feb-3d2a-833c-06cf8f0a3490",
        "key": "D",
        "text": "there was a military leader, K’iche’ Achí, who in *Rabinal Achí*"
      }
    ],
    "correct_option_id": "2a3d269f-1fb0-3abd-8904-f3f48b16d463",
    "explanation": "Choice A is the best answer. The modifier “Based on events…by a king,” is describing the drama “Rabinal Achí.” Modifiers need to be next to the subjects they describe, so “Rabinal Achí” needs to be the first word after the comma.\n\nChoice B is incorrect. This doesn’t complete the text in a way that conforms to the conventions of Standard English. The modifier “Based on events…by a king,” is describing the drama “Rabinal Achí.” Modifiers need to be next to the subjects they describe, so “Rabinal Achí” needs to be the first word after the comma. Choice C is incorrect. This doesn’t complete the text in a way that conforms to the conventions of Standard English. The modifier “Based on events…by a king,” is describing the drama “Rabinal Achí.” Modifiers need to be next to the subjects they describe, so “Rabinal Achí” needs to be the first word after the comma. Choice D is incorrect. This doesn’t complete the text in a way that conforms to the conventions of Standard English. The modifier “Based on events…by a king,” is describing the drama “Rabinal Achí.” Modifiers need to be next to the subjects they describe, so “Rabinal Achí” needs to be the first word after the comma.",
    "source_id": "f0864217",
    "source_number": 33,
    "authored_distractors": false
  },
  {
    "id": "f6b3a119-8a75-5e4c-8800-166731da48d6",
    "external_key": "SAT_RW:c91ef0f0",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "HARD",
    "prompt": "During the American Civil War, Thomas Morris Chester braved the front lines as a war correspondent for the *Philadelphia Press*. Amplifying the voices and experiences of Black soldiers ______ of particular importance to Chester, who later became an activist and lawyer during the postwar Reconstruction period.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "8900d073-e381-3f8a-8284-f3b04828ac68",
        "key": "A",
        "text": "were"
      },
      {
        "id": "a29aef29-767f-373f-b775-7ec6a79e7bf9",
        "key": "B",
        "text": "have been"
      },
      {
        "id": "73595a68-97e0-30be-b2cd-6dba00c42757",
        "key": "C",
        "text": "are"
      },
      {
        "id": "df3aa053-a40d-326f-9261-54083ccf925b",
        "key": "D",
        "text": "was"
      }
    ],
    "correct_option_id": "df3aa053-a40d-326f-9261-54083ccf925b",
    "explanation": "Choice D is the best answer. The convention being tested is subject-verb agreement. The singular verb \"was\" agrees in number with the singular subject \"amplifying.\" Gerunds such as \"amplifying\" are always singular.\n\nChoice A is incorrect because the plural verb \"were\" doesn’t agree in number with the singular subject \"amplifying.\" Choice B is incorrect because the plural verb \"have been\" doesn’t agree in number with the singular subject \"amplifying.\" Choice C is incorrect because the plural verb \"are\" doesn’t agree in number with the singular subject \"amplifying.\"",
    "source_id": "c91ef0f0",
    "source_number": 34,
    "authored_distractors": false
  },
  {
    "id": "8c8dae1a-5f45-586d-b7ec-d9e262ea7fb1",
    "external_key": "SAT_RW:fced396a",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "HARD",
    "prompt": "The Herfindahl-Hirschman Index (HHI), a commonly used measure of competition between companies in a particular market, ranges from a score of zero to 10,000 points. Compared with that of a highly concentrated market—that is, a market controlled by very few companies—______\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "eed73f34-d21e-3be4-9272-1a1b87644ce1",
        "key": "A",
        "text": "a market that is less concentrated will have a much lower HHI score."
      },
      {
        "id": "b81b0da1-c0f4-3869-bf92-8ca8fe21abbf",
        "key": "B",
        "text": "the HHI score of a less concentrated market will be much lower."
      },
      {
        "id": "d4864862-30be-3d15-afd3-b0fd8fcc0334",
        "key": "C",
        "text": "when a market is less concentrated, its HHI score will be much lower."
      },
      {
        "id": "bc5d4464-e3c7-3379-9eba-838365205c05",
        "key": "D",
        "text": "a less concentrated market will have an HHI score that is much lower."
      }
    ],
    "correct_option_id": "b81b0da1-c0f4-3869-bf92-8ca8fe21abbf",
    "explanation": "Choice B is the best answer. The convention being tested is subject-modifier placement. This choice makes the noun phrase \"the HHI...market\" the subject of the sentence and places it immediately after the modifying phrase \"compared...market.\" In doing so, this choice clearly establishes that the HHI score of a less concentrated market—and not another noun in the sentence—is being compared with the HHI score of a highly concentrated market.\n\nChoice A is incorrect because it results in a dangling modifier. The placement of \"a market that is less concentrated\" immediately after the modifying phrase illogically suggests that a market is being compared with an HHI score. Choice C is incorrect because it results in a confusing, illogical sentence. The placement of the modifier \"when a market is less concentrated\" after \"a highly concentrated market\" is contradictory. Furthermore, it’s ambiguous what \"its\" is referring to in \"its HHI score,\" resulting in an illogical comparison. Choice D is incorrect because it results in a dangling modifier. The placement of \"a less concentrated market\" immediately after the modifying phrase illogically suggests that a market is being compared with an HHI score.",
    "source_id": "fced396a",
    "source_number": 35,
    "authored_distractors": false
  },
  {
    "id": "12013c25-3639-5bcd-8530-972707910ae0",
    "external_key": "SAT_RW:4dcedc31",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "HARD",
    "prompt": "For scientists to produce new iron nanoparticles of a specific size or strength, they must first be able to monitor reactions between oxygen and existing iron nanoparticles at a near-atomic level of detail. Fortunately, chemistry ______ and his colleagues at Temple University recently developed a new approach that does just that.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "ed2d4769-10aa-333e-80e8-27389cf6c85a",
        "key": "A",
        "text": "professor Yugang Sun"
      },
      {
        "id": "ea7bd785-f69b-3a78-8c95-1840cf63d196",
        "key": "B",
        "text": "professor Yugang Sun,"
      },
      {
        "id": "d487e783-e644-35bc-ae85-2f22901cba9b",
        "key": "C",
        "text": "professor, Yugang Sun,"
      },
      {
        "id": "1846627e-2d27-3a14-97aa-1af1e4771d57",
        "key": "D",
        "text": "professor, Yugang Sun"
      }
    ],
    "correct_option_id": "ed2d4769-10aa-333e-80e8-27389cf6c85a",
    "explanation": "Choice A is the best answer. The convention being tested is the use of punctuation between titles and proper nouns. No punctuation is needed between the proper noun “Yugang Sun” and the title that describes Sun, “chemistry professor.” Furthermore, no punctuation is needed after “Sun” because “chemistry professor Yugang Sun and his colleagues at Temple University” functions as the coordinated subject of the sentence, and together Sun and colleagues performed the action of developing a new approach to producing iron nanoparticles.\n\nChoice B is incorrect because no punctuation is needed between the proper noun “Yugang Sun” and the coordinated noun phrase “and his colleagues at Temple University.” Choice C is incorrect because no punctuation is needed before or after the proper noun “Yugang Sun.” Setting off the professor’s name with commas suggests that it could be removed without affecting the coherence of the sentence, which isn’t the case. Choice D is incorrect because no punctuation is needed between the title “chemistry professor” and the proper noun “Yugang Sun.”",
    "source_id": "4dcedc31",
    "source_number": 36,
    "authored_distractors": false
  },
  {
    "id": "e461b156-a107-5d87-8fd8-a18738ef03e1",
    "external_key": "SAT_RW:f10b7ce4",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "HARD",
    "prompt": "In the list “Adorable Things” from Sei Shōnagon’s *Pillow Book*, the author delights in baby sparrows, a face drawn on a melon, and a young courtier in ceremonial garb. So shrewd an observer is Shōnagon, a lady-in-waiting to Empress Teishi, that her book’s musings on tenth-century Japanese courtly life ______ readers a thousand years later.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "2d1a7699-a220-3921-81c8-668b6e7aa5c7",
        "key": "A",
        "text": "fascinate"
      },
      {
        "id": "66071751-3ca2-3879-b538-da74e9c41943",
        "key": "B",
        "text": "has fascinated"
      },
      {
        "id": "b74df907-2116-3ae5-8a52-639acfb43f83",
        "key": "C",
        "text": "fascinates"
      },
      {
        "id": "15b13385-18b6-3e37-9dc4-91a7a99503bb",
        "key": "D",
        "text": "is fascinating"
      }
    ],
    "correct_option_id": "2d1a7699-a220-3921-81c8-668b6e7aa5c7",
    "explanation": "Choice A is the best answer. The convention being tested is subject-verb agreement. The plural verb \"fascinate\" agrees in number with the plural subject \"musings.\"\n\nChoice B is incorrect because the singular verb \"has fascinated\" doesn’t agree in number with the plural subject \"musings.\" Choice C is incorrect because the singular verb \"fascinates\" doesn’t agree in number with the plural subject \"musings.\" Choice D is incorrect because the singular verb \"is fascinating\" doesn’t agree in number with the plural subject \"musings.\"",
    "source_id": "f10b7ce4",
    "source_number": 37,
    "authored_distractors": false
  },
  {
    "id": "3ca54af9-6a73-5940-bfc2-788086a6e1ec",
    "external_key": "SAT_RW:5bed774c",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "HARD",
    "prompt": "Philosopher Peter Kivy was a leading figure in musical ______ evidenced by his belief that instead of evoking particular emotions, such as sadness or joy, compositions elicit a listener’s emotional response to the structure and artistry of the music itself, Kivy’s approach to the study of music was decidedly formalist.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "d7776106-acf7-3ac9-aca1-f2bf7cba25d2",
        "key": "A",
        "text": "aesthetics as"
      },
      {
        "id": "56fff903-f9c9-38b0-bea6-46bb01aa32a4",
        "key": "B",
        "text": "aesthetics and as"
      },
      {
        "id": "e0b19394-d7a9-3d39-a4bd-0d0537769517",
        "key": "C",
        "text": "aesthetics, as"
      },
      {
        "id": "8b7fbf1c-5116-34db-99c0-28cffbd5b698",
        "key": "D",
        "text": "aesthetics. As"
      }
    ],
    "correct_option_id": "8b7fbf1c-5116-34db-99c0-28cffbd5b698",
    "explanation": "Choice D is the best answer. The convention being tested is punctuation use between sentences. In this choice, the period is used correctly to mark the boundary between one sentence (\"Philosopher...aesthetics\") and another (\"As...formalist\"). The long adverbial element \"as evidenced...itself\" modifies the content in the following clause to support the claim that Kivy’s approach was formalist.\n\nChoice A is incorrect because it results in a run-on sentence. The sentences (\"Philosopher...aesthetics\" and \"As…formalist\") are fused without punctuation and/or a conjunction. Choice B is incorrect. Without a comma preceding it, the conjunction \"and\" can’t be used in this way to join sentences. Choice C is incorrect because it results in a comma splice. A comma can’t be used in this way to mark the boundary between sentences.",
    "source_id": "5bed774c",
    "source_number": 38,
    "authored_distractors": false
  },
  {
    "id": "61aeda14-6eb6-5c59-b93d-0d211a7d0523",
    "external_key": "SAT_RW:9c3630b9",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "HARD",
    "prompt": "Using natural debris, such as dried ______ such as plastic bags; and more traditional art supplies, such as tree glue, Ghanaian artist Ed Franklin Gavua creates his striking Yiiiiikakaii African masks, which he hopes can help viewers rethink how waste is used in their communities.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "eecb267c-1207-3370-b908-d892f0be631d",
        "key": "A",
        "text": "leaves, man-made trash:"
      },
      {
        "id": "62e1151a-877d-3aad-98a6-956532b9427d",
        "key": "B",
        "text": "leaves; man-made trash,"
      },
      {
        "id": "4b0da501-dfc0-30b5-ab66-9f97be9f89bb",
        "key": "C",
        "text": "leaves, man-made trash,"
      },
      {
        "id": "fec311d4-f9c3-3ed0-bb39-87a5135c4f07",
        "key": "D",
        "text": "leaves; man-made trash;"
      }
    ],
    "correct_option_id": "62e1151a-877d-3aad-98a6-956532b9427d",
    "explanation": "Choice B is the best answer. The convention being tested is the punctuation of elements in a complex series. It’s conventional to use a semicolon to separate items in a complex series with internal punctuation, and in this choice, the semicolon after \"leaves\" is conventionally used to separate the first item (\"natural debris, such as dried leaves\") and the second item (\"man-made trash, such as plastic bags\") in the series of materials used by Gavua. Further, the comma after \"trash\" correctly separates the noun phrase \"man-made trash\" from the supplementary phrase (\"such as plastic bags\") that describes it.\n\nChoice A is incorrect because a comma after \"leaves\" doesn’t match the semicolon used later to separate the second and third items in the series (\"man-made...bags\" and \"and...glue\"). Additionally, it’s not conventional to use a colon in this way to separate a supplementary phrase (\"such as plastic bags\") from the noun phrase it modifies (\"man-made trash\"). Choice C is incorrect because a comma after \"leaves\" doesn’t match the semicolon used later to separate the second and third items in the series (\"man-made...bags\" and \"and...glue\"). Choice D is incorrect because it’s not conventional to use a semicolon in this way to separate a supplementary phrase (\"such as plastic bags\") from the noun phrase it modifies (\"man-made trash\").",
    "source_id": "9c3630b9",
    "source_number": 39,
    "authored_distractors": false
  },
  {
    "id": "7e6d8da0-c131-551e-85e9-af1d0e25b0f8",
    "external_key": "SAT_RW:3a2d77d7",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "HARD",
    "prompt": "In the 1950s, novel audio technologies allowed the addition of another instrument to jazz and swing ______ relatively quiet instrument, its full range of sound was finally audible alongside the blaring brass instruments of the time, allowing flautists like Bennie Maupin and Bobbi Humphrey to perform with other jazz greats.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "ac497571-461f-3977-b495-4efd3e3b13e8",
        "key": "A",
        "text": "music, the flute, a"
      },
      {
        "id": "22e1d3ef-e7f0-330d-8a93-26af77abee73",
        "key": "B",
        "text": "music. The flute, a"
      },
      {
        "id": "4ae601e8-2f2e-314b-8b1e-72b982279183",
        "key": "C",
        "text": "music; the flute, a"
      },
      {
        "id": "194ad212-1498-3285-9a4a-0ca05e581eb5",
        "key": "D",
        "text": "music: the flute. A"
      }
    ],
    "correct_option_id": "194ad212-1498-3285-9a4a-0ca05e581eb5",
    "explanation": "Choice D is the best answer. The convention being tested is the use of punctuation within and between sentences. In this choice, the colon correctly introduces the name of the instrument (the flute) that novel audio technologies allowed to be added to jazz and swing. In addition, the period is used to correctly mark the boundary between one sentence (\"In…flute\") and another (\"A relatively…greats\").\n\nChoice A is incorrect because it results in a comma splice. A comma can’t be used in this way to join two main clauses (\"In…quiet instrument\" and \"its…greats\"). Choice B is incorrect. In standard English, it’s unconventional to form a sentence in this way with two uncoordinated subjects (\"the flute\" and \"its full range of sound\"), and the lack of a clear main subject results in an awkwardly constructed and confusing sentence. Choice C is incorrect. In standard English, it’s unconventional to form an independent clause in this way with two uncoordinated subjects (\"the flute\" and \"its full range of sound\"), and the lack of a clear main subject results in an awkwardly constructed and confusing clause.",
    "source_id": "3a2d77d7",
    "source_number": 40,
    "authored_distractors": false
  },
  {
    "id": "bb8f105f-7103-50a1-9f24-863e2c6d04a1",
    "external_key": "SAT_RW:87aa7bab",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "MEDIUM",
    "prompt": "A common assumption among art historians is that the invention of photography in the mid-nineteenth century displaced the painted portrait in the public consciousness. The diminishing popularity of the portrait miniature, which coincided with the rise of photography, seems to support this claim. However, photography’s impact on the portrait miniature may be overstated. Although records from art exhibitions in the Netherlands from 1820 to 1892 show a decrease in the number of both full-sized and miniature portraits submitted, this trend was established before the invention of photography.\n\nBased on the text, what can be concluded about the diminishing popularity of the portrait miniature in the nineteenth century?",
    "options": [
      {
        "id": "a5921a18-b999-3d5c-bfda-4c45faa950de",
        "key": "A",
        "text": "Factors other than the rise of photography may be more directly responsible for the portrait miniature’s decline."
      },
      {
        "id": "2c61b048-f526-3aec-979a-66c64c53d88e",
        "key": "B",
        "text": "Although portrait miniatures became less common than photographs, they were widely regarded as having more artistic merit."
      },
      {
        "id": "f30d1e64-c7cf-3e95-aa28-f019fa7c5a09",
        "key": "C",
        "text": "The popularity of the portrait miniature likely persisted for longer than art historians have assumed."
      },
      {
        "id": "55d29ee1-b93d-3938-b73d-537b83c80c0f",
        "key": "D",
        "text": "As demand for portrait miniatures decreased, portrait artists likely shifted their creative focus to photography."
      }
    ],
    "correct_option_id": "a5921a18-b999-3d5c-bfda-4c45faa950de",
    "explanation": "Choice A is the best answer. The text says that the impact of photography on the portrait miniature might be \"overstated,\" as some records show a decrease in the number of portrait miniatures *before* the invention of photography. From this, we can conclude that factors *other* than the rise of photography may be more directly responsible for the portrait miniature’s decline.\n\nChoice B is incorrect. The text never discusses the \"artistic merit\" of either art form. Choice C is incorrect. The text never suggests that the portrait miniature was popular for longer than historians thought—if anything, it suggests that the portrait miniature started losing its popularity *earlier* than historians thought. Choice D is incorrect. The text never suggests that portrait painters shifted to become photographers.",
    "source_id": "87aa7bab",
    "source_number": 41,
    "authored_distractors": false
  },
  {
    "id": "2a520deb-1967-57ee-9612-0e6162908776",
    "external_key": "SAT_RW:d73a908a",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "MEDIUM",
    "prompt": "Believing that living in an impractical space can heighten awareness and even improve health, conceptual artists Madeline Gins and Shusaku Arakawa designed an apartment building in Japan to be more fanciful than functional. A kitchen counter is chest-high on one side and knee-high on the other; a ceiling has a door to nowhere. The effect is disorienting but invigorating: after four years there, filmmaker Nobu Yamaoka reported significant health benefits.\n\nWhich choice best states the main idea of the text?",
    "options": [
      {
        "id": "e0db85e1-380f-3624-97d5-ace68a7a6c3b",
        "key": "A",
        "text": "Although inhabiting a home surrounded by fanciful features such as those designed by Gins and Arakawa can be rejuvenating, it is unsustainable."
      },
      {
        "id": "7e30c6ed-b9df-3c19-8449-74ddc8cd2881",
        "key": "B",
        "text": "Designing disorienting spaces like those in the Gins and Arakawa building is the most effective way to create a physically stimulating environment."
      },
      {
        "id": "188a3671-8657-3ed9-b514-0b84c663d881",
        "key": "C",
        "text": "As a filmmaker, Yamaoka has long supported the designs of conceptual artists such as Gins and Arakawa."
      },
      {
        "id": "57dcb4cf-0451-349f-a139-d0cc6040b42e",
        "key": "D",
        "text": "Although impractical, the design of the apartment building by Gins and Arakawa may improve the well-being of the building’s residents."
      }
    ],
    "correct_option_id": "57dcb4cf-0451-349f-a139-d0cc6040b42e",
    "explanation": "Choice D is the best answer because it most accurately states the main idea of the text. According to the text, conceptual artists Gins and Arakawa have designed an apartment building that is disorienting because of several unconventional elements, such as uneven kitchen counters and “a door to nowhere.” The text goes on to suggest that there may be benefits to this kind of design because filmmaker Yamaoka lived in the apartment building for four years and reported health benefits. Thus, although the design is impractical, it may improve the well-being of the apartment building’s residents.\n\nChoice A is incorrect. Although the text mentions that Yamaoka lived in the apartment for four years, it doesn’t address how long someone can beneficially live in a home surrounded by fanciful features or whether doing so can be sustained. Choice B is incorrect. Although the text mentions the potential benefits of living in a home with disorienting design features, it doesn’t suggest that this is the most effective method to create a physically stimulating environment. Choice C is incorrect because the text refers to Yamaoka to support the claim that Gins and Arakawa’s apartment building design may be beneficial, but the text doesn’t indicate that Yamaoka supports the designs of other conceptual artists.",
    "source_id": "d73a908a",
    "source_number": 42,
    "authored_distractors": false
  },
  {
    "id": "a1ef4c1d-73dc-50e8-a474-b832d5b3ee92",
    "external_key": "SAT_RW:d748c3fd",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_INFERENCES",
    "topic_name": "Information and Ideas / Inferences",
    "difficulty": "MEDIUM",
    "prompt": "In her 2021 article “Throwaway History: Towards a Historiography of Ephemera,” scholar Anne Garner discusses John Johnson (1882–1956), a devoted collector of items intended to be discarded, including bus tickets and campaign pamphlets. Johnson recognized that scholarly institutions considered his expansive collection of ephemera to be worthless—indeed, it wasn’t until 1968, after Johnson’s death, that Oxford University’s Bodleian Library acquired the collection, having grasped the items’ potential value to historians and other researchers. Hence, the example of Johnson serves to ______\n\nWhich choice most logically completes the text?",
    "options": [
      {
        "id": "aa8dee0a-64f5-3c8c-b423-fd3820c7e5a6",
        "key": "A",
        "text": "demonstrate the difficulties faced by contemporary historians in conducting research at the Bodleian Library without access to ephemera."
      },
      {
        "id": "65d3c14f-d771-3a98-8d28-81f6bbdc731e",
        "key": "B",
        "text": "represent the challenge of incorporating examples of ephemera into the collections of libraries and other scholarly institutions."
      },
      {
        "id": "b4e24e8f-6f08-3625-8cd6-295ffe65feeb",
        "key": "C",
        "text": "lend support to arguments by historians and other researchers who continue to assert that ephemera holds no value for scholars."
      },
      {
        "id": "224df74a-b88c-3f82-91f6-47da0e305b0f",
        "key": "D",
        "text": "illustrate both the relatively low scholarly regard in which ephemera was once held and the later recognition of ephemera’s possible utility."
      }
    ],
    "correct_option_id": "224df74a-b88c-3f82-91f6-47da0e305b0f",
    "explanation": "Choice D is the best answer. Johnson collected “ephemera,” or things that are meant to be thrown away. Scholars thought his collection was worthless to them, then later realized that it was potentially valuable. This suggests that scholars went from disregarding ephemera to recognizing their usefulness.\n\nChoice A is incorrect. This inference isn’t supported. The text tells us that the Bodleian Library acquired Johnson’s large collection of ephemera back in 1968, so we can assume that contemporary historians conducting research there do have access to that collection. Choice B is incorrect. This inference isn’t supported. The text tells us that “Oxford University’s Bodleian Library acquired the collection,” but it never suggests that it was a challenge to do so. Choice C is incorrect. This inference isn’t supported. The text actually suggests the opposite: the example of Johnson’s collection lends support to arguments that ephemera does hold value for scholars.",
    "source_id": "d748c3fd",
    "source_number": 43,
    "authored_distractors": false
  },
  {
    "id": "22f92e77-97b0-5cb3-bf84-83fa82d0cb2f",
    "external_key": "SAT_RW:8c1be131",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "MEDIUM",
    "prompt": "During the World War II era, some Mexican American women adopted a striking new look called *pachuca* style. They wore altered men’s jackets or zoot suits (wide-legged, long-coated suits) and dramatic makeup, and they combed their hair into high, rounded shapes. Some people criticized *pachuca* style, saying it was dangerous and women should dress traditionally. But historians see things differently. They see *pachuca* style as a form of rebellion against the era’s rigid social expectations for women. They say that it showed a desire for self-expression and freedom on the part of women who adopted the style.\n\nAccording to the text, how do historians view *pachuca* style?",
    "options": [
      {
        "id": "46ef7852-5cfd-31c3-9049-5ad1ccf7e5ec",
        "key": "A",
        "text": "They think that *pachuca* style was such a popular trend that it continues to influence fashion in the United States to the present day."
      },
      {
        "id": "ca06977b-9188-3bff-851b-25574b8eea22",
        "key": "B",
        "text": "They think that *pachuca* style was a way for some Mexican American women to express themselves and resist strict social expectations."
      },
      {
        "id": "c6c03da6-c378-3b02-bb3a-b2439305bf45",
        "key": "C",
        "text": "They think that *pachuca* style was celebrated because it enabled some Mexican American women to show their support for the United States during World War II."
      },
      {
        "id": "170834b1-6650-342d-897f-53298125692b",
        "key": "D",
        "text": "They think that *pachuca* style was similar to other fashion trends that different groups of women adopted in the same period."
      }
    ],
    "correct_option_id": "ca06977b-9188-3bff-851b-25574b8eea22",
    "explanation": "Choice B is the best answer because it presents a statement about how historians view pachuca style that is supported by the text. The text first describes the distinctive pachuca style of dress adopted by some Mexican American women during World War II, saying that some criticized it and asserted that women should dress traditionally. The text then goes on to contrast this position with that of historians, who \"see things differently\": according to these historians, the pachuca style showed a wish for freedom and self-expression, and it acted as a kind of rebellion against what society expected of women at the time. Therefore, according to the text, historians think that the pachuca style was a way for Mexican women to express themselves and resist strict social expectations.\n\nChoice A is incorrect because the text explicitly describes the pachuca style as a distinctive look adopted during the World War II era. It does not indicate that the pachuca style influences fashion in the United States in the present day. Choice C is incorrect because the text does not indicate that Mexican American women wore the pachuca style to show support for the United States during World War II; rather, the style was a means of self-expression and rebellion against social expectations. Choice D is incorrect because the text does not compare the pachuca style to other fashion trends: the pachuca style is the only style mentioned.",
    "source_id": "8c1be131",
    "source_number": 44,
    "authored_distractors": false
  },
  {
    "id": "af10b6f4-3b5e-5d48-ac98-4d8942c42fac",
    "external_key": "SAT_RW:92c2564d",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "MEDIUM",
    "prompt": "Utah is home to Pando, a colony of about 47,000 quaking aspen trees that all share a single root system. Pando is one of the largest single organisms by mass on Earth, but ecologists are worried that its growth is declining in part because of grazing by animals. The ecologists say that strong fences could prevent deer from eating young trees and help Pando start thriving again.\n\nAccording to the text, why are ecologists worried about Pando?",
    "options": [
      {
        "id": "e07364da-c24b-375d-afc0-3de30d54a36d",
        "key": "A",
        "text": "It isn’t growing at the same rate it used to."
      },
      {
        "id": "87e9ba1b-6a9e-35a4-9d17-fed854264289",
        "key": "B",
        "text": "It isn’t producing young trees anymore."
      },
      {
        "id": "83d49ee7-b9da-3856-8ce6-41c2602097cd",
        "key": "C",
        "text": "It can’t grow into new areas because it is blocked by fences."
      },
      {
        "id": "bc930ee5-9e99-324b-986c-a6d21bdaec4d",
        "key": "D",
        "text": "Its root system can’t support many more new trees."
      }
    ],
    "correct_option_id": "e07364da-c24b-375d-afc0-3de30d54a36d",
    "explanation": "Choice A is the best answer because it presents an explanation that is directly stated in the text for why ecologists are worried about Pando. The text states that Pando is a colony of about 47,000 quaking aspen trees that represents one of the largest organisms on Earth. According to the text, ecologists are worried that Pando’s growth is declining, partly because animals are feeding on the trees. In other words, the ecologists are worried that Pando isn’t growing at the same rate it used to.\n\nChoice B is incorrect. Rather than indicating that Pando isn’t producing young trees anymore, the text reveals that Pando is indeed producing young trees, stating that those trees can be protected from grazing deer by strong fences. Choice C is incorrect because the text states that fences can be used to prevent deer from eating Pando’s young trees, not that Pando itself can’t grow in new areas because it’s blocked by fences. Choice D is incorrect because the text offers no evidence that Pando’s root system is incapable of supporting new trees or is otherwise a cause of worry for ecologists.",
    "source_id": "92c2564d",
    "source_number": 45,
    "authored_distractors": false
  },
  {
    "id": "bef2aadd-98bb-5db8-8fe1-36add69a0ddf",
    "external_key": "SAT_RW:602b47c7",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "MEDIUM",
    "prompt": "Biologists have predicted that birds’ feather structures vary with habitat temperature, but this hadn’t been tested in mountain environments. Ornithologist Sahas Barve studied feathers from 249 songbird species inhabiting different elevations—and thus experiencing different temperatures—in the Himalayan Mountains. He found that feathers of high-elevation species not only have a greater proportion of warming downy sections to flat and smooth sections than do feathers of low-elevation species, but high-elevation species’ feathers also tend to be longer, providing a thicker layer of insulation.\n\nWhich choice best states the main idea of the text?",
    "options": [
      {
        "id": "40081d80-e47d-355d-b6e1-70e1447a8722",
        "key": "A",
        "text": "Barve’s investigation shows that some species of Himalayan songbirds have evolved feathers that better regulate body temperature than do the feathers of other species, contradicting previous predictions."
      },
      {
        "id": "da4266c0-749a-3d80-bf96-2654ac4ae896",
        "key": "B",
        "text": "Barve found an association between habitat temperature and feather structure among Himalayan songbirds, lending new support to a general prediction."
      },
      {
        "id": "0cd5bf63-5f98-349a-b931-41a0cbbdd523",
        "key": "C",
        "text": "Barve discovered that songbirds have adapted to their environment by growing feathers without flat and smooth sections, complicating an earlier hypothesis."
      },
      {
        "id": "acd51042-3417-367d-9fbf-af0ac6d85045",
        "key": "D",
        "text": "The results of Barve’s study suggest that the ability of birds to withstand cold temperatures is determined more strongly by feather length than feather structure, challenging an established belief."
      }
    ],
    "correct_option_id": "da4266c0-749a-3d80-bf96-2654ac4ae896",
    "explanation": "Choice B is the best answer because it most accurately states the main idea of the text. The first sentence of the text introduces the prediction that the structures of birds’ feathers vary with habitat temperature and notes that this prediction hadn’t been tested in mountain environments. The rest of the text focuses on a study by Barve, an ornithologist. The text indicates that Barve studied feathers of 249 songbird species in habitats at different elevations—and, therefore, different temperatures (as the text establishes that elevation affects temperature)—in the Himalayan Mountains. The text then explains that Barve found that compared to feathers of low-elevation species, feathers of high-elevation species have a greater proportion of warming sections and are of a length that provides more insulation—in other words, feather structure varies with elevation-driven temperature differences. Thus, the main idea of the text is that Barve found an association between habitat temperature and feather structure among Himalayan songbirds and that this finding supports a general prediction that hadn’t previously been tested in mountain environments.\n\nChoice A is incorrect because the text specifically focuses on Barve’s finding of a relationship between feather structure and elevation—which corresponds to temperature differences—and not on the broader claim that some birds have feathers better suited to regulating body temperature than others, without reference to a consistent pattern. Moreover, Barve’s finding supports the prediction presented in the text (that feather structures vary with habitat temperature), and there’s no indication that it contradicts any other predictions. Choice C is incorrect because the text doesn’t indicate that Barve found that songbird species have adapted to their environment by growing feathers without flat and smooth sections; his finding of different proportions of such sections in feathers depending on elevation suggests that they do have flat and smooth sections. Moreover, Barve’s finding supports the prediction presented in the text (that feather structures vary with habitat temperature), and there’s no indication that it complicates any other earlier hypothesis. Choice D is incorrect because the text doesn’t mention a comparison of the effects of feather structure and feather length; in fact, the text suggests that length is part of feather structure, since Barve’s finding concerning structure addresses proportions of warming downy sections and insulation-providing length. Moreover, the text doesn’t refer to an established belief, presenting instead a prediction that hadn’t been tested in mountain environments before Barve conducted his study.",
    "source_id": "602b47c7",
    "source_number": 46,
    "authored_distractors": false
  },
  {
    "id": "47b9caa3-317c-5b24-85ee-e86e396ec97f",
    "external_key": "SAT_RW:29f5c8c2",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "MEDIUM",
    "prompt": "Fish whose DNA has been modified to include genetic material from other species are known as transgenic. Some transgenic fish have genes from jellyfish that result in fluorescence (that is, they glow in the dark). Although these fish were initially engineered for research purposes in the 1990s, they were sold as pets in the 2000s and can now be found in the wild in creeks in Brazil. A student in a biology seminar who is writing a paper on these fish asserts that their escape from Brazilian fish farms into the wild may have significant negative long-term ecological effects.\n\nWhich quotation from a researcher would best support the student’s assertion?",
    "options": [
      {
        "id": "d0bb622c-9c9d-3ccf-8858-42296c1b1b9a",
        "key": "A",
        "text": "“In one site in the wild where transgenic fish were observed, females outnumbered males, while in another the numbers of females and males were equivalent.”"
      },
      {
        "id": "9ce6650b-a289-3865-a610-9cd4dce40a9e",
        "key": "B",
        "text": "“Though some presence of transgenic fish in the wild has been recorded, there are insufficient studies of the impact of those fish on the ecosystems into which they are introduced.”"
      },
      {
        "id": "2cc6c7f5-287a-31f8-b515-0c3f2be24c76",
        "key": "C",
        "text": "“The ecosystems into which transgenic fish are known to have been introduced may represent a subset of the ecosystems into which the fish have actually been introduced.”"
      },
      {
        "id": "0c164ef1-7356-3a26-8f2f-a3a9191c2b07",
        "key": "D",
        "text": "“Through interbreeding, transgenic fish might introduce the trait of fluorescence into wild fish populations, making those populations more vulnerable to predators.”"
      }
    ],
    "correct_option_id": "0c164ef1-7356-3a26-8f2f-a3a9191c2b07",
    "explanation": "Choice D is the best answer because this quotation would best support the student’s assertion that the escape of transgenic fish from Brazilian fish farms into the wild may have significant negative long-term ecological effects. The text explains that transgenic fish have DNA that includes genetic material from other species, that some transgenic fish have genes from jellyfish that make them glow in the dark, and that glow-in-the-dark transgenic fish can now be found in the wild in Brazilian creeks. The quotation indicates why the escape of these fish may have negative long-term ecological effects: glow-in-the-dark transgenic fish might introduce fluorescence into wild fish populations by breeding with wild fish, causing wild fish to glow in the dark and thereby allowing predators to prey on them much more easily.\n\nChoice A is incorrect because this quotation doesn’t mention any negative effects of the introduction of fluorescent transgenic fish into the wild. The quotation merely compares the ratio of females to males at two sites in the wild where transgenic fish have been observed. Choice B is incorrect because this quotation doesn’t support the idea that the escape of fluorescent transgenic fish from Brazilian fish farms may have significant negative long-term ecological effects. Rather, the quotation suggests that more research is needed to understand the effects. Choice C is incorrect because this quotation supports the idea that transgenic fish may be present in more ecosystems than has been observed; it doesn’t address whether the presence of fluorescent transgenic fish affects these ecosystems.",
    "source_id": "29f5c8c2",
    "source_number": 47,
    "authored_distractors": false
  },
  {
    "id": "c6d8e6ed-b780-5e21-b4c2-87135d2687ca",
    "external_key": "SAT_RW:d83c3d54",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "MEDIUM",
    "prompt": "**Characteristics of the Banks of the Provo River Downstream of the Jordanelle Dam**\n*(Data from Graph: Area in square meters across years)*\n- **1987 (Before dam):** Grass cover: ~58,000 m²; Bare soil: ~65,000 m²; Forest cover: ~75,000 m²\n- **1993 (After dam):** Grass cover: ~95,000 m²; Bare soil: ~18,000 m²; Forest cover: ~58,000 m²\n- **2006 (After dam):** Grass cover: ~130,000 m²; Bare soil: ~35,000 m²; Forest cover: ~45,000 m²\n\nThe Jordanelle Dam was built on the Provo River in Utah in 1992. Earth scientist Adriana E. Martinez and colleagues tracked changes to the environment on the banks of the river downstream of the dam, including how much grass and forest cover were present. They concluded that the dam changed the flow of the river in ways that benefited grass plants but didn’t benefit trees.\n\nWhich choice best describes data from the graph that support Martinez and colleagues’ conclusion?",
    "options": [
      {
        "id": "7f8986ed-411d-3865-968d-b928474a20e3",
        "key": "A",
        "text": "The lowest amount of grass cover was approximately 58,000 square meters, and the highest amount of forest cover was approximately 75,000 square meters."
      },
      {
        "id": "2813f04b-0e69-32cb-a5bb-5812680a9b97",
        "key": "B",
        "text": "There was more grass cover than forest cover in 1987, and this difference increased dramatically in 1993 and again in 2006."
      },
      {
        "id": "170ed21c-5c4f-3047-931c-20a329ade033",
        "key": "C",
        "text": "There was less grass cover than bare soil in 1987 but more grass cover than bare soil in 1993 and 2006, whereas there was more forest cover than bare soil in all three years."
      },
      {
        "id": "bc1678e7-7bc8-3f4f-aac3-a1e487e68972",
        "key": "D",
        "text": "Grass cover increased from 1987 to 1993 and from 1993 to 2006, whereas forest cover decreased in those periods."
      }
    ],
    "correct_option_id": "bc1678e7-7bc8-3f4f-aac3-a1e487e68972",
    "explanation": "Choice D is the best answer because it describes data from the graph that support Martinez and colleagues’ conclusion that the Jordanelle Dam led to changes that benefited grass plants but not trees. The graph shows characteristics of the banks of the Provo River downstream of the Jordanelle Dam in three different years—1987, 1993, and 2006. Specifically, the graph shows the amount of grass cover, bare soil, and forest cover in those years. The text indicates that the Jordanelle Dam was built in 1992, meaning that the data from the graph for 1987 reflect conditions before the dam was built, whereas the data for 1993 and 2006 reflect conditions after the dam was built. The data show that grass cover increased substantially from 1987 to 1993 and again from 1993 to 2006. The data also show that forest cover declined over those periods. Together, these data support Martinez and colleagues’ conclusion that the dam was beneficial for grass plants but not for trees—grass cover increased significantly after the dam was built, while forest cover declined.\n\nChoice A is incorrect. Although it is true that, in the graph, the lowest value for grass cover is approximately 58,000 square meters and the highest value for forest cover is approximately 75,000 square meters, both values are from 1987, before the Jordanelle Dam was built in 1992. Therefore, this information alone cannot support Martinez and colleagues’ conclusion about changes in grass and tree cover following the construction of the dam. Choice B is incorrect because it presents an inaccurate description of data from the graph. The graph shows that there was more forest cover than grass cover in 1987, not that there was more grass cover than forest cover that year. Choice C is incorrect because, while it accurately reflects data from the graph when it compares grass cover and forest cover to bare soil, these data alone cannot support Martinez and colleagues’ conclusion that the dam led to changes that benefited grass plants but not trees. An increase in grass cover relative to bare soil following the construction of the dam might indicate that the dam benefited grass plants, but the fact that there was more forest cover than bare soil in all three years doesn’t indicate that the dam failed to benefit trees.",
    "source_id": "d83c3d54",
    "source_number": 48,
    "authored_distractors": false
  },
  {
    "id": "f9f46378-337c-5ea9-8134-e6bdde5b5f55",
    "external_key": "SAT_RW:ca5a3fb4",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_INFERENCES",
    "topic_name": "Information and Ideas / Inferences",
    "difficulty": "MEDIUM",
    "prompt": "The practice of logging (cutting down trees for commercial and other uses) is often thought to be at odds with forest conservation (the work of preserving forests). However, a massive study in forest management and preservation spanning 700,000 hectares in Oregon’s Malheur National Forest calls that view into question. So far, results of the study suggest that forest plots that have undergone limited logging (the careful removal of a controlled number of trees) may be more robust than plots that haven’t been logged at all. These results, in turn, suggest that ______\n\nWhich choice most logically completes the text?",
    "options": [
      {
        "id": "3a8aeca2-cae1-3825-9ebd-11f4516188e0",
        "key": "A",
        "text": "logging may be useful for maintaining healthy forests, provided it is limited."
      },
      {
        "id": "0c6d0231-d4ee-3233-a83a-2fc655aa37c6",
        "key": "B",
        "text": "other forest management strategies are more effective than limited logging."
      },
      {
        "id": "f6cb7cb2-60a3-3a5b-a4f3-1e132baeb77e",
        "key": "C",
        "text": "as time passes, it will be difficult to know whether limited logging has any benefits."
      },
      {
        "id": "db02645b-52cc-3789-a769-7cc3ac3a6213",
        "key": "D",
        "text": "the best way to support forest health may be to leave large forests entirely untouched."
      }
    ],
    "correct_option_id": "3a8aeca2-cae1-3825-9ebd-11f4516188e0",
    "explanation": "Choice A is the best answer because it most logically completes the text’s discussion of the potential effects of logging on forest conservation. The text begins by stating that logging practices are often thought of as being contrary to forest conservation efforts. Then, the text presents the results of a research study examining the effect of limited logging practices on specific forest plots, finding that the plots with limited logging may be \"more robust\" (healthier) than the plots that hadn’t been logged at all. Given these results, it follows that logging may be a useful practice for maintaining healthy forests if it is practiced in a limited way.\n\nChoice B is incorrect because the study referenced in the text only provides information on limited logging as a potential forest management strategy. There is no information in the text about how other forest management strategies support forest conservation efforts. Therefore, the text does not support the assertion that other forest management strategies are more successful than limited logging. Choice C is incorrect because the text presents a research study with findings that specific plots of forest with limited logging may be more robust than the forest plots that were not logged. Rather than suggesting that it is hard to know whether limited logging might be beneficial, the text suggests that the practice could be useful in forest conservation efforts. Choice D is incorrect. The text discusses the results of a research study that compares the health of forest plots with limited logging to forest plots that were not logged. It does not take a position on the best way to support forest health but rather presents a research study with findings that question conventionally held thoughts regarding the practice of logging.",
    "source_id": "ca5a3fb4",
    "source_number": 49,
    "authored_distractors": false
  },
  {
    "id": "0ddfb241-bf29-5a42-83a7-f625a44f46aa",
    "external_key": "SAT_RW:95388117",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "MEDIUM",
    "prompt": "**Land Area Covered by Native Flowering Plants at a Site in Antarctica**\n\n| Species | Area covered in 2009 (in square meters) | Area covered in 2018 (in square meters) | Percent increase in area covered from 2009 to 2018 |\n| :--- | :--- | :--- | :--- |\n| *Deschampsia antarctica* | 1,230 | 1,576 | 28% |\n| *Colobanthus quitensis* | 6.9 | 10.7 | 55% |\n\nThe only flowering plant species native to Antarctica, *Colobanthus quitensis* and *Deschampsia antarctica* grow in places where the earth remains free of ice for much of the year. Botanist Niccoletta Cannone wondered how the warming of Antarctica’s climate in recent years had affected these species, so she visited a site in Antarctica, first in 2009 and later in 2018, to count the number of plants growing there. Cannone found that the area of land covered by the two species had significantly expanded during the nine-year period. While both species likely benefited from warming temperatures, *Colobanthus quitensis* ______\n\nWhich choice most effectively uses data from the table to complete the comparison?",
    "options": [
      {
        "id": "553c096e-95b5-39fa-ba62-f97a427c808b",
        "key": "A",
        "text": "suppressed the growth of *Deschampsia antarctica*, which covered a smaller area of land in 2018 than it had in 2009."
      },
      {
        "id": "68d3a103-66bb-364b-a9bc-c9e5e0cfcfe2",
        "key": "B",
        "text": "saw a greater expansion than *Deschampsia antarctica* did, increasing the area of land it covered by more than half."
      },
      {
        "id": "f410ad1e-2875-3b0a-a3b0-913c1adb72d3",
        "key": "C",
        "text": "showed a greater increase in the average size of individual plants than *Deschampsia antarctica* did."
      },
      {
        "id": "2f40401a-b489-340f-a0ac-e283376dd7c3",
        "key": "D",
        "text": "covered land newly freed from ice at a rate 55% faster than that of *Deschampsia antarctica*."
      }
    ],
    "correct_option_id": "68d3a103-66bb-364b-a9bc-c9e5e0cfcfe2",
    "explanation": "Choice B is the best answer because it most effectively uses data from the table to complete the comparison of how *Colobanthus quitensis* benefited from warming temperatures with how *Deschampsia antarctica* benefited from them. The table shows the land area covered by these two plant species at a site in Antarctica. According to the table, *Colobanthus quitensis* increased the area it covered by 55% from 2009 to 2018, whereas *Deschampsia antarctica* increased the area it covered by 28% during the same period. It therefore follows that *Colobanthus quitensis* saw a greater expansion than *Deschampsia antarctica* did and that *Colobanthus quitensis* increased the area of land it covered by more than half.\n\nChoice A is incorrect because according to the table, *Deschampsia antarctica* covered 1,230 square meters of land in 2009 and 1,576 square meters of land in 2018. *Deschampsia antarctica* therefore covered a larger, not a smaller, area of land in 2018 than in 2009. Moreover, there’s no information in the text or the table that suggests that one species of the plant suppressed the other. Choice C is incorrect because it inaccurately describes the data in the table. The table shows the land area covered by *Colobanthus quitensis* and *Deschampsia antarctica* and the percent increase in area covered by the two species from 2009 to 2018, not the average size of individual plants belonging to the two species. The data in the table therefore can’t be used to make a comparison of the increase in individual plants’ average size. Choice D is incorrect because the table shows the land area covered by *Colobanthus quitensis* and *Deschampsia antarctica* and the percent increase in area covered by the two species from 2009 to 2018, not the rate at which the species increased the area they covered. Moreover, there’s nothing in the table or the text that suggests that the areas covered by the two species were newly freed from ice.",
    "source_id": "95388117",
    "source_number": 50,
    "authored_distractors": false
  },
  {
    "id": "dd6cd7d3-dc32-5169-ab29-067184f4f335",
    "external_key": "SAT_RW:757077f9",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "MEDIUM",
    "prompt": "During a 2014 archaeological dig in Spain, Vicente Lull and his team uncovered the skeleton of a woman from El Algar, an Early Bronze Age society, buried with valuable objects signaling a high position of power. This finding may persuade researchers who have argued that Bronze Age societies were ruled by men to ______ that women may have also held leadership roles.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "9b412922-1d77-32d8-a69e-b79cfd8637b9",
        "key": "A",
        "text": "waive"
      },
      {
        "id": "f9c0dd7f-7b1a-37dc-8c73-52568ffc85e0",
        "key": "B",
        "text": "concede"
      },
      {
        "id": "a7f0f1d5-8153-3123-8b0c-86615dfbbf08",
        "key": "C",
        "text": "refute"
      },
      {
        "id": "2669d3ce-cd5b-3ab8-b352-8123844f0392",
        "key": "D",
        "text": "require"
      }
    ],
    "correct_option_id": "f9c0dd7f-7b1a-37dc-8c73-52568ffc85e0",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion of the significance of the 2014 archaeological finding at El Algar. In this context, “concede” means to admit something is true after first resisting that admission. The text indicates that some researchers believe “Bronze Age societies were ruled by men.” But the Bronze Age burial of a woman at El Algar included “valuable objects signaling a high position of power,” which would raise the possibility that “women may have also held leadership roles.” Thus, the text is calling into question the notion that only men were leaders in these societies and speculating that people holding this view may reconsider their opinion.\n\nChoice A is incorrect because “waive” means to refrain from insisting that something, such as a right or a requirement, be observed; the word isn’t used, however, in contexts where someone acknowledges that an opinion they hold may be invalid, as is the case in the text. Choice C is incorrect. According to the text, the finding from the El Algar burial site undermines the view that Bronze Age societies were exclusively ruled by men. However, “refute” means to demonstrate that something is false and would not make sense in context. Lull and team’s finding supports the view that women may have also held leadership roles, not that they did not participate in such roles. Choice D is incorrect because in this context, “require” means to demand or specify as mandatory. However, it would not make sense for contemporary researchers to demand that Bronze Age “women may have also held leadership roles.”",
    "source_id": "757077f9",
    "source_number": 51,
    "authored_distractors": false
  },
  {
    "id": "8006ec3f-72aa-520d-8efe-bdd8b3a18037",
    "external_key": "SAT_RW:2af2016f",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "MEDIUM",
    "prompt": "A study by Dr. Paul Hanel and colleagues concluded that people are more likely to behave politely when listening to ideas they disagree with if they think about values before they engage in a discussion. Study participants were assigned to one of two groups. The experimental group spent a few minutes writing about one of their personal values before they had a group discussion on a controversial topic. And the control group spent a few minutes writing about a drink (tea, milk, etc.) before their group discussion on that topic. Hanel and colleagues found that the experimental group’s discussion was more civil than the control group’s discussion was.\n\nWhich choice best describes the main purpose of the text?",
    "options": [
      {
        "id": "375bc618-46aa-38c1-8dfe-a12ecc050fd2",
        "key": "A",
        "text": "To describe a widely held belief and how a study’s results support that belief"
      },
      {
        "id": "7db392d9-a984-339e-a37f-88a9825eb9eb",
        "key": "B",
        "text": "To argue that researchers were surprised by the results of a certain study"
      },
      {
        "id": "df8623b8-a3e2-306f-b925-984f96757e74",
        "key": "C",
        "text": "To suggest ways to improve a certain study’s experimental design"
      },
      {
        "id": "0c1c2584-133c-3209-b45e-cc8e0e42c280",
        "key": "D",
        "text": "To explain a study’s conclusion and how a research team arrived at that conclusion"
      }
    ],
    "correct_option_id": "0c1c2584-133c-3209-b45e-cc8e0e42c280",
    "explanation": "Choice D is the best answer because it most accurately describes the main purpose of the text, which is to explain a study’s conclusion and how researchers involved in the study arrived at that conclusion. The text begins by summarizing the main conclusion of the study conducted by Paul Hanel and colleagues: when confronted with ideas they disagree with in discussions about controversial topics, people are more likely to respond politely if they think about their personal values before engaging in such discussions. The text then goes on to describe the design of Hanel and colleagues’ experiment. By comparing interactions between members of an experimental group (who had been prompted to write about their personal values beforehand) to those between members of a control group (who had been prompted to write about a beverage), the team found that people in the experimental group behaved more civilly, or politely, than people in the control group did during discussions about a controversial topic. This finding led to the conclusion described at the beginning of the text.\n\nChoice A is incorrect. Although the text discusses the results of a study, it doesn’t provide any indication that the conclusion the study supported—that when facing disagreement, people behave more politely when they have thought about their values—is a belief that is widely held. Choice B is incorrect because the text doesn’t indicate that the researchers found the results of their study to be surprising, or contrary to what they expected. In fact, there’s no indication provided in the text about how the researchers felt about the study’s results or that the results should be considered surprising. Choice C is incorrect. Although the text discusses the experimental design of a study, it doesn’t suggest any improvements to that design; instead, it focuses on how the design enabled the researchers to draw a particular conclusion.",
    "source_id": "2af2016f",
    "source_number": 52,
    "authored_distractors": false
  },
  {
    "id": "461c20aa-f086-5d43-9116-1d29d3662ad2",
    "external_key": "SAT_RW:b13378c8",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "MEDIUM",
    "prompt": "Early in the Great Migration of 1910–1970, which involved the mass migration of Black people from the southern to the northern United States, political activist and *Chicago Defender* writer Fannie Barrier Williams was instrumental in helping other Black women establish themselves in the North. Many women hoped for better employment opportunities in the North because, in the South, they faced much competition for domestic employment and men tended to get agricultural work. To aid with this transition, Barrier Williams helped secure job placement in the North for many women before they even began their journey.\n\nWhich choice best states the main purpose of the text?",
    "options": [
      {
        "id": "0b34f394-232c-3047-a420-6a0594d77ea6",
        "key": "A",
        "text": "To introduce and illustrate Barrier Williams’s integral role in supporting other Black women as their circumstances changed during part of the Great Migration"
      },
      {
        "id": "42af7569-6f2a-35ae-a06f-bf92cf1b6ada",
        "key": "B",
        "text": "To establish that Barrier Williams used her professional connections to arrange employment for other Black women, including jobs with the *Chicago Defender*"
      },
      {
        "id": "3740ab5a-97f3-30b5-9253-936fa08ee654",
        "key": "C",
        "text": "To demonstrate that the factors that motivated the start of the Great Migration were different for Black women than they were for Black men"
      },
      {
        "id": "0a361014-5454-338b-9bd0-dc68955e918f",
        "key": "D",
        "text": "To provide an overview of the employment challenges faced by Black women in the agricultural and domestic spheres in the southern United States"
      }
    ],
    "correct_option_id": "0b34f394-232c-3047-a420-6a0594d77ea6",
    "explanation": "Choice A is the best answer because it most accurately describes the text’s purpose, which is to discuss the important role Barrier Williams played in supporting many other Black women as they relocated to the northern United States during the early years of the Great Migration. After introducing Barrier Williams, the text describes how she helped find jobs for other Black women, who in many cases relocated in search of better employment prospects than the South could offer at the time. The text indicates that by doing so, she eased these women’s transition as their circumstances changed.\n\nChoice B is incorrect. Although the text mentions Barrier Williams’s work as a political activist and writer for the *Chicago Defender*, it doesn’t discuss any professional connections she made in these roles or indicate that she used any such connections in her work to secure employment for other Black women. Choice C is incorrect. Although the text discusses a factor that caused many women to relocate during the Great Migration, their difficulty finding employment in the South, the text doesn’t indicate that this factor motivated the start of the Great Migration. Moreover, the text doesn’t discuss the factors that motivated Black men to migrate. Choice D is incorrect. Although the text mentions the difficult employment prospects for Black women in the domestic and agricultural sectors in the South during the Great Migration, the text’s main purpose isn’t to provide an overview of the employment challenges Black women faced in these sectors. Rather, it provides this information to show that Barrier Williams played a crucial role in supporting many Black women who relocated to the North by helping them achieve one of their main goals, securing a job.",
    "source_id": "b13378c8",
    "source_number": 53,
    "authored_distractors": false
  },
  {
    "id": "a83802c7-8502-52b7-a406-8ce385660977",
    "external_key": "SAT_RW:97e5bf55",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_CROSS_TEXT_CONNECTIONS",
    "topic_name": "Craft and Structure / Cross-Text Connections",
    "difficulty": "MEDIUM",
    "prompt": "**Text 1**\nIn 1916, H. Dugdale Sykes disputed claims that *The Two Noble Kinsmen* was coauthored by William Shakespeare and John Fletcher. Sykes felt Fletcher’s contributions to the play were obvious—Fletcher had a distinct style in his other plays, so much so that lines with that style were considered sufficient evidence of Fletcher’s authorship. But for the lines not deemed to be by Fletcher, Sykes felt that their depiction of women indicated that their author was not Shakespeare but Philip Massinger.\n\n**Text 2**\nScholars have accepted *The Two Noble Kinsmen* as coauthored by Shakespeare since the 1970s: it appears in all major one-volume editions of Shakespeare’s complete works. Though scholars disagree about who wrote what exactly, it is generally held that on the basis of style, Shakespeare wrote all of the first act and most of the last, while John Fletcher authored most of the three middle acts.\n\nBased on the texts, both Sykes in Text 1 and the scholars in Text 2 would most likely agree with which statement?",
    "options": [
      {
        "id": "683d08c0-29a0-3e39-95cd-279752df78c8",
        "key": "A",
        "text": "John Fletcher’s writing has a unique, readily identifiable style."
      },
      {
        "id": "a6a29e0d-0269-3102-bac3-57dab17edfc9",
        "key": "B",
        "text": "The women characters in John Fletcher’s plays are similar to the women characters in Philip Massinger’s plays."
      },
      {
        "id": "1c465894-cf47-39fd-ad70-672885bd7c59",
        "key": "C",
        "text": "*The Two Noble Kinsmen* belongs in one-volume compilations of Shakespeare’s complete plays."
      },
      {
        "id": "45824678-8aca-3c12-9cf2-cff2f0364291",
        "key": "D",
        "text": "Philip Massinger’s style in the first and last acts of *The Two Noble Kinsmen* is an homage to Shakespeare’s style."
      }
    ],
    "correct_option_id": "683d08c0-29a0-3e39-95cd-279752df78c8",
    "explanation": "Choice A is the best answer. Text 1 states that Sykes felt Fletcher’s contributions to the play were obvious because he had a distinct style in his other plays. Text 2 states that scholars generally agree “on the basis of style” that Fletcher wrote most of the three middle acts. Both texts imply that Fletcher’s writing has a unique, readily identifiable style that can be used to distinguish his work from others.\n\nChoice B is incorrect. While Text 1 refers to the women in Massinger plays, neither text compares the women of Fletcher’s plays to the women of Massinger’s plays. Text 2 doesn’t mention Massinger at all. Choice C is incorrect. Text 1 states that Sykes disputed that Shakespeare coauthored the play, and implied that it was coauthored by Fletcher and Massinger instead. Sykes, therefore, would disagree that *The Two Noble Kinsmen* belongs in a Shakespeare compilation. Choice D is incorrect. Text 1 doesn’t suggest that Massinger was inspired by Shakespeare, and Text 2 doesn’t mention Massinger at all.",
    "source_id": "97e5bf55",
    "source_number": 54,
    "authored_distractors": false
  },
  {
    "id": "59be634b-d0ce-5c11-aae0-179cc4ff2d10",
    "external_key": "SAT_RW:236fee8e",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "MEDIUM",
    "prompt": "Archeological excavation of Market Street Chinatown, a nineteenth-century Chinese American community in San Jose, California, provided the first evidence that Asian food products were imported to the United States in the 1800s: bones from a freshwater fish species native to Southeast Asia. <u>Jinshanzhuang—Hong Kong–based import/export firms—likely coordinated the fish’s transport from Chinese-operated fisheries in Vietnam and Malaysia to North American markets.</u> This route reveals the (often overlooked) multinational dimensions of the trade networks linking Chinese diaspora communities.\n\nWhich choice best describes the function of the underlined sentence in the text as a whole?",
    "options": [
      {
        "id": "4b1552c6-9c33-3b9e-b46a-c3f6fb714883",
        "key": "A",
        "text": "It explains why efforts to determine the country of origin of the items mentioned in the previous sentence remain inconclusive."
      },
      {
        "id": "842a26e4-a9c5-3bc2-9c5a-454945474d47",
        "key": "B",
        "text": "It provides information that helps support a claim about a discovery’s significance that is presented in the following sentence."
      },
      {
        "id": "5603c35f-9618-3bee-940c-636fab814336",
        "key": "C",
        "text": "It traces the steps that were taken to locate and recover the objects that are described in the previous sentence."
      },
      {
        "id": "7eea245d-2a2d-307b-8032-c57fe9ea16b5",
        "key": "D",
        "text": "It outlines a hypothesis that additional evidence discussed in the following sentence casts some doubt on."
      }
    ],
    "correct_option_id": "842a26e4-a9c5-3bc2-9c5a-454945474d47",
    "explanation": "Choice B is the best answer. The underlined sentence provides information about import/export firms, showing how Chinese communities across the world were connected by trade routes.\n\nChoice A is incorrect. The underlined sentence never suggests that the countries of origin of the fish are in question—in fact, it tells us exactly where they came from. Choice C is incorrect. The passage never describes the steps taken to discover the fish bones described in the previous sentence. Choice D is incorrect. The underlined sentence doesn’t outline a hypothesis but instead provides evidence. And the following sentence agrees with the underlined sentence, so we could eliminate this choice just for saying that the following sentence \"casts some doubt on\" the underlined one—partly wrong is all wrong.",
    "source_id": "236fee8e",
    "source_number": 55,
    "authored_distractors": false
  },
  {
    "id": "4c992c37-cef4-5bcf-bb63-a553ba70942b",
    "external_key": "SAT_RW:be612a26",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "MEDIUM",
    "prompt": "Recent measurements of the mass of the *W* boson (a subatomic particle) were notable not only for the mere fact that the particle’s mass differed from expectations but for the ______ of that difference: the measured mass of the *W* boson was seven standard deviations higher than predicted by the standard model of particle physics.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "67b81e9e-1765-302c-b30a-32b13ef18130",
        "key": "A",
        "text": "cause"
      },
      {
        "id": "2a30cbe8-36f0-390c-b310-73b310bb0b6b",
        "key": "B",
        "text": "existence"
      },
      {
        "id": "3b078497-c54c-38f4-95e7-5287bac4fe89",
        "key": "C",
        "text": "implication"
      },
      {
        "id": "d8425c27-adeb-35a3-8ed8-9db3c835e6f7",
        "key": "D",
        "text": "scale"
      }
    ],
    "correct_option_id": "d8425c27-adeb-35a3-8ed8-9db3c835e6f7",
    "explanation": "Choice D is the best answer because it most logically completes the text’s discussion of the *W* boson. In this context, \"scale\" means size or extent. The text indicates that recent measurements of the *W* boson were remarkable because they revealed the subatomic particle’s mass to be much greater (\"seven standard deviations higher\") than had been expected based on a standard model. This context conveys not only that the measurements differed from predictions but also that the extent of the difference was very large.\n\nChoice A is incorrect. Although the text indicates that there was a very large difference between the predicted mass and the actual measured mass of the subatomic particle, it doesn’t explain the cause of, or reason behind, that difference. Choice B is incorrect because it wouldn’t make sense to say that the measurements of the subatomic particle were notable because they differed from expectations and also because a difference existed between the measurements and what had been predicted; the text would be repeating the idea that there was a difference instead of adding to that idea. Choice C is incorrect because the text doesn’t convey any implications of, or consequences of or conclusions drawn from, the fact that the mass of the subatomic particle differed from expectations; the context indicates only that the actual measured mass was much higher than the predicted mass.",
    "source_id": "be612a26",
    "source_number": 56,
    "authored_distractors": false
  },
  {
    "id": "c2c2a7f9-b5d3-5f60-a67d-bf82f837c64d",
    "external_key": "SAT_RW:3f37eb3b",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "MEDIUM",
    "prompt": "People sometimes dismiss a claim if it comes from a source they regard as self-interested, but from a strictly logical perspective, the source of a claim is ______: it has no direct bearing on whether the claim is true.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "7bd078d8-1746-37ab-84cf-c0030deee85d",
        "key": "A",
        "text": "indistinct"
      },
      {
        "id": "8dfd4fc7-8155-37da-b9df-4d875e1fea8d",
        "key": "B",
        "text": "irrelevant"
      },
      {
        "id": "8d017fd2-8d4f-33fe-95e7-794292d13b97",
        "key": "C",
        "text": "indisputable"
      },
      {
        "id": "7069083b-b3c1-3e60-aee1-a8842303be06",
        "key": "D",
        "text": "implicit"
      }
    ],
    "correct_option_id": "8dfd4fc7-8155-37da-b9df-4d875e1fea8d",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion about people’s tendency to dismiss claims from sources perceived as self-interested, or acting for their own advantage. In this context, \"irrelevant\" means not applicable to the matter at hand. The text explains that as a matter of logical reasoning, the source of a claim has nothing to do with the claim’s truthfulness—a claim is either true or false in actuality, regardless of where it originates. This context suggests that even though people may distrust a claim based on its source, the source of the claim is actually irrelevant.\n\nChoice A is incorrect because in this context, \"indistinct\" would mean uncertain or not clearly recognizable. Instead of suggesting that the source of a claim can’t be determined with certainty, the text suggests that recognizing a source and having an opinion of it simply doesn’t matter because as a matter of logic, a claim is true or false in actuality, regardless of where it originates. Choice C is incorrect because in this context, \"indisputable\" would mean impossible to question or deny. Although the text suggests that it isn’t logical to assume a claim is false just because its source appears to be self-interested, it doesn’t go so far as to suggest that the source of a claim can’t be questioned—the text instead makes the point that from a logical standpoint, the source of a claim doesn’t matter because the claim is either true or false in and of itself. Choice D is incorrect because in this context, \"implicit\" would mean suggested or understood without being directly expressed. Nothing in the text suggests that logically, the source of a claim is only suggested; instead of addressing whether sources can be directly identified, the text focuses on the idea that sources don’t matter because a claim is true or false in actuality, regardless of where it originates.",
    "source_id": "3f37eb3b",
    "source_number": 57,
    "authored_distractors": false
  },
  {
    "id": "008034c0-318d-5f44-abb8-a21f967c3645",
    "external_key": "SAT_RW:cef79fb9",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "MEDIUM",
    "prompt": "The Bayeux Tapestry, from eleventh-century France, depicts 75 scenes over 250 feet of fabric. It was likely produced by workers embroidering in sections and then joining the resulting panels together. It’s plausible that the workshop that produced the tapestry had never produced one so large, and some researchers claim that a close examination of the joins—the places where the panels are stitched together—suggests that the workers developed and refined their joining process over the course of production. <u>For example, the first join the workers completed exhibits a clear misalignment of the borders of the two panels, whereas the later joins are virtually invisible.</u>\n\nWhich choice best describes the function of the underlined sentence in the text as a whole?",
    "options": [
      {
        "id": "6c2f7be4-2ccb-3882-963c-a88c9b3a559e",
        "key": "A",
        "text": "It identifies the people and events depicted in the Bayeux Tapestry."
      },
      {
        "id": "ecf360fa-e916-3b26-aa72-9d26ddcc38a0",
        "key": "B",
        "text": "It supports an argument about the workers who produced the Bayeux Tapestry."
      },
      {
        "id": "f35c9b95-2392-38e7-a80f-286f44de0c70",
        "key": "C",
        "text": "It compares the Bayeux Tapestry with other tapestries from eleventh-century France."
      },
      {
        "id": "86c10f0d-7784-326e-bff3-6745073e58e5",
        "key": "D",
        "text": "It describes how researchers determined where the Bayeux Tapestry was produced."
      }
    ],
    "correct_option_id": "ecf360fa-e916-3b26-aa72-9d26ddcc38a0",
    "explanation": "Choice B is the best answer because it most accurately describes the function of the underlined sentence in the text as a whole. The text discusses the Bayeux Tapestry, making the point that the workers who produced the huge tapestry in the eleventh century might not have ever produced a tapestry so large before. The text goes on to suggest that because of this lack of previous experience, the workers developed and refined the process of joining the tapestry’s panels over time as they worked. The last sentence of the text then provides an example of an observation that suggests the workers’ process changed: clear misalignment of the borders of the two panels the workers joined first and virtually invisible joins completed later. Thus, the underlined sentence serves to support an argument about the workers who produced the tapestry.\n\nChoice A is incorrect because the example given in the last sentence of the text has to do with how the panels of the Bayeux Tapestry were joined by the workers, not with what is depicted in those panels; the text never identifies any people or places depicted in the tapestry. Choice C is incorrect because the last sentence compares how early panels in the Bayeux Tapestry were joined with how later panels in the same tapestry were joined; it doesn’t make any comparison between the Bayeux Tapestry and other tapestries from the same time in France. Choice D is incorrect because the last sentence doesn’t address the location where the Bayeux Tapestry was created; the first sentence of the text presents it as a given that the tapestry was created in France, but nothing in the text indicates how that origin was determined.",
    "source_id": "cef79fb9",
    "source_number": 58,
    "authored_distractors": false
  },
  {
    "id": "a3ae80a9-4dc2-5f0b-a727-2316b4c7cb7e",
    "external_key": "SAT_RW:4974b053",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "MEDIUM",
    "prompt": "Although science fiction was dominated mostly by white male authors when Octavia Butler, a Black woman, began writing, she did not view the genre as ______: Butler broke into the field with the publication of several short stories and her 1976 novel *Patternmaster*, and she later became the first science fiction writer to win a prestigious MacArthur Fellowship.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "f6e97c8d-5463-395c-8fcc-6c394e2ceec0",
        "key": "A",
        "text": "legitimate"
      },
      {
        "id": "2d4d9a26-6fde-3e58-a302-ec2609389f47",
        "key": "B",
        "text": "impenetrable"
      },
      {
        "id": "e21780e9-d978-35cc-bd49-a5d1fa853d12",
        "key": "C",
        "text": "compelling"
      },
      {
        "id": "3fa7b9e4-b419-3bd0-a999-40a22e13a5ee",
        "key": "D",
        "text": "indecipherable"
      }
    ],
    "correct_option_id": "2d4d9a26-6fde-3e58-a302-ec2609389f47",
    "explanation": "Choice B is the best answer because it most logically completes the discussion of Octavia Butler’s career. In this context, “impenetrable” means impossible to enter. The text indicates that the field of science fiction was dominated by white males when Butler, a Black woman, started writing, but she published several science fiction short stories and a novel and later won a prestigious award; that is, Butler pursued science fiction writing and had success. This context suggests that Butler didn’t view the genre as impossible to enter.\n\nChoice A is incorrect. In this context, “legitimate” would mean genuinely good or valid. Nothing in the text suggests that Butler didn’t think the science fiction genre was good or valid; in fact, it indicates that she pursued and made a successful career of publishing work in that field. Choice C is incorrect. In this context, “compelling” would mean attracting or demanding attention. The text indicates that Butler chose to write science fiction, so it wouldn’t make sense to say that she didn’t see the field as drawing her attention. Choice D is incorrect. To say that Butler didn’t consider science fiction “indecipherable,” or impossible to understand, would suggest that Butler did understand it. However, the text doesn’t address Butler’s ability to interpret works in the genre; rather, it focuses on Butler’s successful pursuit of writing science fiction.",
    "source_id": "4974b053",
    "source_number": 59,
    "authored_distractors": false
  },
  {
    "id": "fe824c00-aa0b-5f30-8a74-cb306c2f460d",
    "external_key": "SAT_RW:7d8224f9",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_STRUCTURE_PURPOSE",
    "topic_name": "Craft and Structure / Text Structure and Purpose",
    "difficulty": "MEDIUM",
    "prompt": "In 1154, Muhammad al-Idrisi completed a collection of maps of the lands known to medieval Arabic and European scholars. This collection was titled *Al-Kitāb al-Rujārī* (*The Book of Roger*), after the Norman king Roger II who hired him to create it. To create the collection, al-Idrisi consulted Arabic and Greek maps and interviewed travelers about the lands they visited. He included these travelers’ stories alongside the map illustrations.\n\nWhich choice best states the main purpose of the text?",
    "options": [
      {
        "id": "9b7dce0c-6b6f-31d2-b34e-81faff84fe84",
        "key": "A",
        "text": "To discuss the benefits of studying mapmaking"
      },
      {
        "id": "6e7a37d0-59b3-37eb-9c47-8534953f8240",
        "key": "B",
        "text": "To explain how travelers created maps"
      },
      {
        "id": "1c44c951-9f59-3f61-983f-e156540e323e",
        "key": "C",
        "text": "To describe a collection of medieval maps and how it was created"
      },
      {
        "id": "b710b621-b54a-3a1b-acf1-4bec707d5d08",
        "key": "D",
        "text": "To compare medieval Arabic and Greek mapmaking techniques"
      }
    ],
    "correct_option_id": "1c44c951-9f59-3f61-983f-e156540e323e",
    "explanation": "Choice C is the best answer because it most accurately states the main purpose of the text, which is to describe a collection of medieval maps and how it was created. The text begins by mentioning Muhammad al-Idrisi’s collection of maps of lands known to medieval Arabic and European scholars. It then states that the Norman king Roger II hired al-Idrisi to create the collection and details al-Idrisi’s methods of creation: consulting Arabic and Greek maps and interviewing travelers. In short, the text presents a collection of medieval maps and then goes on to describe how that collection came to be.\n\nChoice A is incorrect because the text describes a collection of maps and the process of creating that collection but does not discuss the benefits of studying mapmaking in general. Choice B is incorrect because though the text mentions that al-Idrisi interviewed travelers, the text does not describe how those travelers created maps. Choice D is incorrect because though the text mentions that al-Idrisi consulted Arabic and Greek maps, the text does not offer a comparison of Arabic and Greek mapmaking techniques.",
    "source_id": "7d8224f9",
    "source_number": 60,
    "authored_distractors": false
  },
  {
    "id": "8ff6dc43-1f96-57b0-9558-78a5634e74cd",
    "external_key": "SAT_RW:a40c7aa3",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "Most of the planets that have been discovered outside our solar system orbit G-type stars, like our Sun. In 2014, ______ researchers identified a planet orbiting KELT-9, a B-type star more than twice as massive and nearly twice as hot as the Sun. Called KELT-9b, it is one of the hottest planets ever discovered.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "2f49c9aa-bf81-3705-b9cb-479bc71f76fc",
        "key": "A",
        "text": "likewise,"
      },
      {
        "id": "8cbd0be8-5568-32e1-b05f-89bd157139f1",
        "key": "B",
        "text": "however,"
      },
      {
        "id": "ea76d221-cb7d-3ec1-9c9d-0713d54c2bc4",
        "key": "C",
        "text": "therefore,"
      },
      {
        "id": "a4027dd7-4311-328b-b716-6eed57825be5",
        "key": "D",
        "text": "for example,"
      }
    ],
    "correct_option_id": "8cbd0be8-5568-32e1-b05f-89bd157139f1",
    "explanation": "Choice B is the best answer. The word “however” logically signals that the information in this sentence about the planet KELT-9b—that it orbits a B-type star—contrasts with the previous information about planets discovered outside our solar system. Most of these planets orbit G-type stars, not B-type stars.\n\nChoice A is incorrect because “likewise” illogically signals that the information about the planet KELT-9b is similar to the previous information about most planets outside our solar system. Instead, it contrasts with that information. Choice C is incorrect because “therefore” illogically signals that the information about the planet KELT-9b is a result of the previous information about most planets outside our solar system. Instead, it contrasts with that information. Choice D is incorrect because “for example” illogically signals that the information about the planet KELT-9b is an example of the previous information about most planets outside our solar system. Instead, it contrasts with that information.",
    "source_id": "a40c7aa3",
    "source_number": 61,
    "authored_distractors": false
  },
  {
    "id": "d3ec6e2f-bc78-546b-a011-54cf8f22147c",
    "external_key": "SAT_RW:8a1ad52b",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "A research team led by Gal Badihi has discovered that chimpanzees communicate through exchanges of gestures occurring at a pace similar to that of human conversations. ______ chimpanzee gesture exchanges have short pauses of about 120 milliseconds between communications, comparable to the 200-millisecond average pause between turns in human speech.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "31a37929-48d1-3592-8a99-82a8051b7ad6",
        "key": "A",
        "text": "As a result,"
      },
      {
        "id": "68e102ad-326f-34c0-a2a4-aa439680f808",
        "key": "B",
        "text": "Specifically,"
      },
      {
        "id": "cefc91cd-3e9f-30db-ac04-7ee6c33bd3b7",
        "key": "C",
        "text": "By contrast,"
      },
      {
        "id": "07964b79-9c70-3ba9-9c28-82675fef82bd",
        "key": "D",
        "text": "Nevertheless,"
      }
    ],
    "correct_option_id": "68e102ad-326f-34c0-a2a4-aa439680f808",
    "explanation": "Choice B is the best answer. “Specifically” logically signals that the information in this sentence—that pauses between chimpanzee gestures average about 120 milliseconds, comparable to the 200-millisecond average pause in human speech—provides specific, precise details elaborating on the previous sentence’s claim about the pace of chimpanzee communication being similar to that of human conversations.\n\nChoice A is incorrect because “as a result” illogically signals that this sentence presents a result or consequence of the claim about chimpanzee communication described in the previous sentence. Instead, the sentence provides specific details elaborating on that claim. Choice C is incorrect because “by contrast” illogically signals that the information about chimpanzee gesture exchanges in this sentence contrasts with the previous sentence’s claim about the pace of chimpanzee communication being similar to that of human conversations. Instead, the sentence provides specific details elaborating on that claim. Choice D is incorrect because “nevertheless” illogically signals that the information about chimpanzee gesture exchanges in this sentence is true despite the previous claim about the pace of chimpanzee communication. Instead, the sentence provides specific details elaborating on that claim.",
    "source_id": "8a1ad52b",
    "source_number": 62,
    "authored_distractors": false
  },
  {
    "id": "f6e0e725-bb41-5cd4-9190-743e75a4228e",
    "external_key": "SAT_RW:af89fa02",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "The Babylonian king Hammurabi achieved much during his forty-year reign. He conquered all of Mesopotamia and built Babylon into one of the most powerful cities of the ancient world. Today, ______ he is mainly remembered for a code of laws inscribed on a seven-foot-tall block of stone: the Code of Hammurabi.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "bb5177f2-a5d8-31a7-8a43-484fe7532818",
        "key": "A",
        "text": "therefore,"
      },
      {
        "id": "ef325a56-2efa-307d-80ea-0df896bce97f",
        "key": "B",
        "text": "likewise,"
      },
      {
        "id": "a3af59a8-94ba-356c-84eb-1f76b8da115e",
        "key": "C",
        "text": "however,"
      },
      {
        "id": "8baca8e3-098c-33db-a39d-eee583995713",
        "key": "D",
        "text": "for instance,"
      }
    ],
    "correct_option_id": "a3af59a8-94ba-356c-84eb-1f76b8da115e",
    "explanation": "Choice C is the best answer. “However” logically signals that the information in this sentence—that Hammurabi is mainly remembered for just a single achievement, the Code of Hammurabi—is contrary to what might be assumed from the previous information about Hammurabi’s many achievements.\n\nChoice A is incorrect because “therefore” illogically signals that the information in this sentence is a result of the previous information about Hammurabi’s many achievements. Instead, this sentence makes a point that is contrary to what might be assumed from the previous information. Choice B is incorrect because “likewise” illogically signals that the information in this sentence is similar to the previous information about Hammurabi’s many achievements. Instead, this sentence makes a point that is contrary to what might be assumed from the previous information. Choice D is incorrect because “for instance” illogically signals that this sentence exemplifies the previous information about Hammurabi’s many achievements. Instead, this sentence makes a point that is contrary to what might be assumed from the previous information.",
    "source_id": "af89fa02",
    "source_number": 63,
    "authored_distractors": false
  },
  {
    "id": "ddfea0a0-64cd-5b76-9671-0521d0b5d556",
    "external_key": "SAT_RW:4c43bf61",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "MEDIUM",
    "prompt": "While researching a topic, a student has taken the following notes:\n- The International Center for the Arts of the Americas (ICAA) is directed by Mari Carmen Ramírez.\n- Ramírez oversaw an initiative to create an online archive of historical documents related to the history of Latin American and Latino visual art.\n- The ICAA digitized over 10,000 documents, including the writings of Latin American and Latino artists and critics.\n- The creation of the archive didn’t require historical documents to be removed from their countries of origin.\n- Scholars now have more access to these documents.\n\nThe student wants to explain an advantage of the ICAA’s archive being digital. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "841d3602-73f6-367f-8965-d854c1a4af0a",
        "key": "A",
        "text": "Over 10,000 documents related to the history of Latin American and Latino visual art are part of the ICAA archive."
      },
      {
        "id": "c338748f-cc29-3184-aa3b-ef486c6c801c",
        "key": "B",
        "text": "By offering online versions of historical documents, the ICAA’s archive provides more access to these materials without removing them from their countries of origin."
      },
      {
        "id": "58156ca0-1d19-36ff-a1db-d585eebdfeaa",
        "key": "C",
        "text": "Among the historical documents in the ICAA’s archive are the writings of Latin American and Latino artists and critics."
      },
      {
        "id": "4836a92c-342b-3aa0-b300-3bc7da774bdd",
        "key": "D",
        "text": "The ICAA’s director, Mari Carmen Ramírez, oversaw the creation of an online archive of historical documents related to Latin American and Latino visual art."
      }
    ],
    "correct_option_id": "c338748f-cc29-3184-aa3b-ef486c6c801c",
    "explanation": "Choice B is the best answer. The sentence explains an advantage of the ICAA’s archive being digital, noting that the archive provides more access to historical documents since they don’t have to be removed from their countries of origin.\n\nChoice A is incorrect. The sentence emphasizes the number of documents in the ICAA archive; it doesn’t explain an advantage of the archive being digital. Choice C is incorrect. The sentence notes the types of historical documents the ICAA’s archive contains; it doesn’t explain an advantage of the archive being digital. Choice D is incorrect. The sentence identifies who oversaw the creation of the ICAA’s online archive; it doesn’t explain an advantage of the archive being digital.",
    "source_id": "4c43bf61",
    "source_number": 64,
    "authored_distractors": false
  },
  {
    "id": "b62908b1-a760-5faf-8b17-af9540a55b85",
    "external_key": "SAT_RW:16631d34",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "MEDIUM",
    "prompt": "While researching a topic, a student has taken the following notes:\n- The Million Song Dataset (MSD) includes main audio features and descriptive tags for popular songs.\n- Audio features include acoustic traits such as loudness and pitch intervals.\n- Many algorithms use these audio features to predict a new song’s popularity.\n- These algorithms may fail to accurately identify main audio features of a song with varying acoustic traits.\n- Algorithms based on descriptive tags that describe fixed traits such as genre are more reliable predictors of song popularity.\n\nThe student wants to explain a disadvantage of relying on audio features to predict a song’s popularity. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "a16b9ca1-4bd0-34b7-9da7-5941013c4570",
        "key": "A",
        "text": "Many popularity-predicting algorithms are based on a song’s audio features, such as loudness and pitch intervals."
      },
      {
        "id": "737e694b-337a-336d-b64d-aa4f46fd80e3",
        "key": "B",
        "text": "Algorithms based on audio features may misidentify the main features of a song with varying acoustic traits, making such algorithms less reliable predictors of popularity than those based on fixed traits."
      },
      {
        "id": "6d2fff82-0e8a-3b2b-ae0b-64ee37b95a7a",
        "key": "C",
        "text": "Audio features describe acoustic traits such as pitch intervals, which may vary within a song, whereas descriptive tags describe fixed traits such as genre, which are reliable predictors of popularity."
      },
      {
        "id": "00f66dd6-277a-394b-acf5-b4566587a18a",
        "key": "D",
        "text": "The MSD’s descriptive tags are reliable predictors of a song’s popularity, as the traits they describe are fixed."
      }
    ],
    "correct_option_id": "737e694b-337a-336d-b64d-aa4f46fd80e3",
    "explanation": "Choice B is the best answer. This choice uses relevant information from the notes to explain a disadvantage of relying on audio features to predict a song’s popularity—namely, that it may misidentify features of certain songs. It also contrasts audio features with descriptive tags, which are more reliable predictors.\n\nChoice A is incorrect. This choice only states a fact about the algorithms without evaluating their reliability or accuracy. Choice C is incorrect. This choice only describes the difference between audio features and descriptive tags without indicating why this difference matters for predicting popularity. Choice D is incorrect. This choice only mentions descriptive tags, which are not the focus of the student’s rhetorical goal.",
    "source_id": "16631d34",
    "source_number": 65,
    "authored_distractors": false
  },
  {
    "id": "943e5f1e-c91b-5e70-9e28-24b3c88e9325",
    "external_key": "SAT_RW:d9dad012",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "The Inca of South America used intricately knotted string devices called quipus to record countable information, like population data and payments. ______ they may have used quipus to record more complex information, like stories and myths, according to researchers.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "8d883116-1cc6-3020-bb00-4bcda7fb8450",
        "key": "A",
        "text": "As a result,"
      },
      {
        "id": "c57cdf82-4ed9-328e-b653-bcac90d6b7df",
        "key": "B",
        "text": "In other words,"
      },
      {
        "id": "98148ee4-497d-3867-abd7-3a06742f3038",
        "key": "C",
        "text": "In addition,"
      },
      {
        "id": "9e0c7d19-3e38-3313-9432-2f82420b097e",
        "key": "D",
        "text": "For example,"
      }
    ],
    "correct_option_id": "98148ee4-497d-3867-abd7-3a06742f3038",
    "explanation": "Choice C is the best answer. \"In addition\" logically signals that the claim in this sentence—that the Inca of South America may have used quipus to record more complex information—is an additional point related to the previous statement about the Inca using quipus to record countable information.\n\nChoice A is incorrect because \"as a result\" illogically signals that the claim in the sentence is a consequence or result of the previous statement about the Inca using quipus to record countable information. Instead, the possibility that the Inca used quipus to record more complex information is an additional point about how the quipus were used. Choice B is incorrect because \"in other words\" illogically signals that the claim in the sentence is merely a paraphrase or restatement of the previous statement about the Inca using quipus to record countable information. Instead, the possibility that the Inca used quipus to record more complex information is an additional point about how the quipus were used. Choice D is incorrect because \"for example\" illogically signals that the claim in the sentence exemplifies the previous statement about the Inca using quipus to record countable information. Instead, the possibility that the Inca used quipus to record more complex information is an additional point about how the quipus were used.",
    "source_id": "d9dad012",
    "source_number": 66,
    "authored_distractors": false
  },
  {
    "id": "02eb6729-e897-5b32-8c23-327ad004f678",
    "external_key": "SAT_RW:601b9d18",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "Some members of the US Supreme Court have resisted calls to televise the court’s oral arguments, concerned that the participants would be tempted to perform for the cameras (and thus lower the quality of the discourse). ______ the justices worry that most viewers would not even watch the full deliberations, only short clips that could be misinterpreted and mischaracterized.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "02ef54b3-e19d-3082-8315-f27de9f97e0e",
        "key": "A",
        "text": "However,"
      },
      {
        "id": "dfc50145-8cfb-32bb-bd3f-0d93b899ad8e",
        "key": "B",
        "text": "Additionally,"
      },
      {
        "id": "b6266081-03b7-3c20-8919-a2e4ee20f718",
        "key": "C",
        "text": "In comparison,"
      },
      {
        "id": "5ee745ae-edcd-3301-b4c0-c0155da6889a",
        "key": "D",
        "text": "For example,"
      }
    ],
    "correct_option_id": "dfc50145-8cfb-32bb-bd3f-0d93b899ad8e",
    "explanation": "Choice B is the best answer. “Additionally” logically signals that the claim in this sentence—that some Supreme Court justices worry that viewers (of televised court arguments) would watch only short, misleading clips—adds to the information in the previous sentence. Specifically, the previous sentence indicates one concern raised by those opposed to televising the court’s oral arguments, and the claim that follows indicates a second, additional concern.\n\nChoice A is incorrect because “however” illogically signals that the claim in this sentence contrasts with the information in the previous sentence. Instead, the claim adds to the information, indicating a second, additional concern that some Supreme Court justices have about televising the court’s arguments. Choice C is incorrect because “in comparison” illogically signals that the claim in this sentence is being compared to the information in the previous sentence. Instead, the claim adds to the information, indicating a second, additional concern that some Supreme Court justices have about televising the court’s arguments. Choice D is incorrect because “for example” illogically signals that the claim in this sentence exemplifies the information in the previous sentence. Instead, the claim adds to the information, indicating a second, additional concern that some Supreme Court justices have about televising the court’s arguments.",
    "source_id": "601b9d18",
    "source_number": 67,
    "authored_distractors": false
  },
  {
    "id": "438863f2-a202-5c50-8b50-49374d143286",
    "external_key": "SAT_RW:60917233",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "In the 1880s, inventor Lewis Latimer improved upon Thomas Edison’s design for the electric light bulb. ______ Latimer made the light bulb more durable by placing cardboard around its carbon filament. With this innovation, Latimer became the first Black inventor to contribute to the electrification of the world.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "7cd411ec-f893-388e-bad1-bfffd958d09d",
        "key": "A",
        "text": "Soon,"
      },
      {
        "id": "aed8ab60-f787-3da1-b6ef-535fcf270e19",
        "key": "B",
        "text": "Regardless,"
      },
      {
        "id": "a9410200-36dd-3b4a-be55-61f799d23ef3",
        "key": "C",
        "text": "However,"
      },
      {
        "id": "98202844-d480-356d-9b2d-50223da36fa7",
        "key": "D",
        "text": "Specifically,"
      }
    ],
    "correct_option_id": "98202844-d480-356d-9b2d-50223da36fa7",
    "explanation": "Choice D is the best answer. \"Specifically\" logically signals that the information in this sentence—Latimer making the light bulb more durable—provides a specific detail elaborating on the more general claim in the previous sentence that Latimer improved the light bulb.\n\nChoice A is incorrect because \"soon\" illogically signals that the information in this sentence occurred shortly after Latimer improved the light bulb. Instead, Latimer making the bulb more durable was the specific improvement. Choice B is incorrect because \"regardless\" illogically signals that the information in this sentence is true despite the previous claim about Latimer. Instead, the information about Latimer making the bulb more durable provides a specific detail elaborating on that claim. Choice C is incorrect because \"however\" illogically signals that the information in this sentence contrasts with the previous claim about Latimer. Instead, the information about Latimer making the bulb more durable provides a specific detail elaborating on that claim.",
    "source_id": "60917233",
    "source_number": 68,
    "authored_distractors": false
  },
  {
    "id": "b6c06992-1d4a-51e9-b38d-ddf5ab4c0e44",
    "external_key": "SAT_RW:ec3d7605",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "Award-winning travel writer Linda Watanabe McFerrin considers the background research she conducts on destinations featured in her travel books to be its own reward. ______ McFerrin admits to finding the research phase of her work just as fascinating and engaging as exploring a location in person.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "2c9aafda-357b-39b2-af42-f429ac340bd0",
        "key": "A",
        "text": "By contrast,"
      },
      {
        "id": "b9d04855-c66c-3f38-9859-37b16998bf2d",
        "key": "B",
        "text": "Likewise,"
      },
      {
        "id": "25558536-beba-3139-be3d-1a63fb5c94ea",
        "key": "C",
        "text": "Besides,"
      },
      {
        "id": "4c9dc9a0-034e-3281-adac-b8247115bb4d",
        "key": "D",
        "text": "In fact,"
      }
    ],
    "correct_option_id": "4c9dc9a0-034e-3281-adac-b8247115bb4d",
    "explanation": "Choice D is the best answer. “In fact” logically signals that the information in this sentence—that McFerrin finds the research phase of her work to be just as fascinating as travel—emphasizes and elaborates on the previous sentence’s point that McFerrin regards background research as a rewarding activity.\n\nChoice A is incorrect because “by contrast” illogically signals that the information in this sentence contrasts with the previous sentence’s point about McFerrin’s attitude toward background research. Instead, it emphasizes and elaborates on that point. Choice B is incorrect because “likewise” illogically signals that this sentence merely adds a second, similar point to the previous sentence’s point about McFerrin’s attitude toward background research. Instead, it emphasizes and elaborates on that point. Choice C is incorrect because “besides” illogically signals that this sentence provides a separate point in addition to, or apart from, the previous sentence’s point about McFerrin’s attitude toward background research. Instead, it emphasizes and elaborates on that point.",
    "source_id": "ec3d7605",
    "source_number": 69,
    "authored_distractors": false
  },
  {
    "id": "008afd2c-7637-592c-a83b-5f1a0097409e",
    "external_key": "SAT_RW:a819d8b6",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "MEDIUM",
    "prompt": "In 1873, Spanish scientist Santiago Ramón y Cajal observed that brain fibers have distinct boundaries with clear end points, a finding that went against earlier assumptions about the brain. ______ scientists had assumed that the brain was a continuous web of fused fibers, not a vast network of distinct, individual cells.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "f63e0142-3c7a-3235-a1ca-5815e350e3a7",
        "key": "A",
        "text": "However,"
      },
      {
        "id": "5436571a-00e6-3b2b-b430-4ed7c7d590dd",
        "key": "B",
        "text": "Previously,"
      },
      {
        "id": "165c29e1-8c72-3715-a00a-2027e735bd52",
        "key": "C",
        "text": "As a result,"
      },
      {
        "id": "675d78dc-7f0a-36b2-a2fe-9efeeac48c44",
        "key": "D",
        "text": "Likewise,"
      }
    ],
    "correct_option_id": "5436571a-00e6-3b2b-b430-4ed7c7d590dd",
    "explanation": "Choice B is the best answer. “Previously” logically signals that the fused fiber theory came before Ramón y Cajal’s discovery.\n\nChoice A is incorrect. “However” illogically signals that the fused fiber theory in this sentence contrasts with the information in the previous sentence. While this theory does contrast with Ramón y Cajal’s discovery, the previous sentence concludes by stating that his discovery went against prior assumptions about the brain. The fact that the fused fiber theory was one of those earlier assumptions makes “however” an illogical choice. Choice C is incorrect because “as a result” illogically signals that the fused fiber theory in this sentence was a result of the discovery in the previous sentence. Instead, the fused fiber theory came before Ramón y Cajal’s discovery. Choice D is incorrect because “likewise” illogically signals that the fused fiber theory in this sentence was similar to the discovery in the previous sentence. Instead, the fused fiber theory, which came before Ramón y Cajal’s discovery, was very different from it.",
    "source_id": "a819d8b6",
    "source_number": 70,
    "authored_distractors": false
  },
  {
    "id": "b75b3137-12e1-59ef-8796-3ea8a8594c30",
    "external_key": "SAT_RW:0f39b19c",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "MEDIUM",
    "prompt": "After a spate of illnesses as a child, Wilma Rudolph was told she might never walk again. Defying all odds, Rudolph didn’t just walk, she ______ the 1960 Summer Olympics in Rome, she won both the 100- and 200-meter dashes and clinched first place for her team in the 4x100-meter relay, becoming the first US woman to win three gold medals in a single Olympics.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "918abbb3-478c-359c-a38b-d91804b31970",
        "key": "A",
        "text": "ran—fast—during"
      },
      {
        "id": "57f63d8f-29b3-3513-be69-e8c9a87be4ce",
        "key": "B",
        "text": "ran—fast during"
      },
      {
        "id": "780d9df7-eeda-3f5d-ab2c-3b0dfcfaa93c",
        "key": "C",
        "text": "ran—fast, during"
      },
      {
        "id": "721613d8-bdf0-3780-be79-1e6bafd30aef",
        "key": "D",
        "text": "ran—fast. During"
      }
    ],
    "correct_option_id": "721613d8-bdf0-3780-be79-1e6bafd30aef",
    "explanation": "Choice D is the best answer. The convention being tested is punctuation use between sentences. In this choice, the period is used correctly to mark the boundary between one sentence (“Defying…fast”) and another sentence that begins with a supplementary phrase (“During…Olympics”).\n\nChoice A is incorrect. When a dash is present in a sentence (“ran—fast”), it’s not conventional to use another dash (“fast—during”) to mark the boundary between sentences because it creates a potentially confusing sentence. In this context, a period, semicolon, or colon would be clear and more conventional. Choice B is incorrect because it results in a run-on sentence. The sentences (“Defying…fast”) and (“during…Olympics”) are fused without punctuation and/or a conjunction. Choice C is incorrect because it results in a comma splice. A comma can’t be used in this way to mark the boundary between sentences.",
    "source_id": "0f39b19c",
    "source_number": 71,
    "authored_distractors": false
  },
  {
    "id": "e1c40693-9b0a-578f-91e8-6134d9c9419f",
    "external_key": "SAT_RW:6e193b19",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "MEDIUM",
    "prompt": "Professional American football player Fred Cox invented one of the world’s most popular toys. In the 1970s, he came up with the idea for the Nerf football, which ______ of the harder and heavier regulation football.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "6f9e2fae-e3d9-36a5-88d8-08fe3574cb14",
        "key": "A",
        "text": "were a smaller, foam version"
      },
      {
        "id": "5dfb2159-ad2d-3e22-bbd3-03f8ea68aa5d",
        "key": "B",
        "text": "are smaller, foam versions"
      },
      {
        "id": "0a9d5d7d-597d-3d1f-b90f-1f20d2f83d50",
        "key": "C",
        "text": "were smaller, foam versions"
      },
      {
        "id": "317bb43b-566a-3e96-a4fc-aee5666ad2ab",
        "key": "D",
        "text": "is a smaller, foam version"
      }
    ],
    "correct_option_id": "317bb43b-566a-3e96-a4fc-aee5666ad2ab",
    "explanation": "Choice D is the best answer. The convention being tested is subject-verb agreement and agreement between nouns. The singular verb “is” and the singular noun “version” both agree in number with the relative pronoun “which.” In this context, “which” functions as a singular subject because it refers to the singular noun “the Nerf football.”\n\nChoice A is incorrect because the plural verb “were” doesn’t agree in number with the singular noun phrase “the Nerf football” that it’s modifying. Choice B is incorrect because the plural verb “are” and the plural noun “versions” don’t agree in number with the singular noun phrase “the Nerf football” that they’re modifying. Choice C is incorrect because the plural verb “were” and the plural noun “versions” don’t agree in number with the singular noun phrase “the Nerf football” that they’re modifying.",
    "source_id": "6e193b19",
    "source_number": 72,
    "authored_distractors": false
  },
  {
    "id": "d851e963-ed54-571f-846a-4df2dbe1477c",
    "external_key": "SAT_RW:819c443d",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "MEDIUM",
    "prompt": "In January 1776, Thomas Paine published *Common Sense*, an appeal for freedom from the British monarchy that famously helped ignite the desire for independence among the American colonists. After the colonies achieved their independence, Paine moved to Paris, where the provocative ______ would contribute to another revolution—the French Revolution.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "d98ed60a-9784-3e3c-ba0c-a93c81b3fe8f",
        "key": "A",
        "text": "authors political writings"
      },
      {
        "id": "ea885c58-8098-312b-96c6-85169f0636ca",
        "key": "B",
        "text": "author’s political writings"
      },
      {
        "id": "0220226f-6d8e-3197-b6b5-1fdb6eacbd98",
        "key": "C",
        "text": "author’s political writing’s"
      },
      {
        "id": "5c5c1260-c90a-3a73-99c9-4b8c60087315",
        "key": "D",
        "text": "authors’ political writings’"
      }
    ],
    "correct_option_id": "ea885c58-8098-312b-96c6-85169f0636ca",
    "explanation": "Choice B is the best answer. The conventions being tested are the use of plural and possessive nouns. The singular possessive noun \"author’s\" correctly indicates that the political writings are those of Thomas Paine, and the plural noun \"writings\" correctly indicates that multiple works by Paine are being discussed.\n\nChoice A is incorrect because the context requires the singular possessive noun \"author’s,\" not the plural noun \"authors.\" Choice C is incorrect because the context requires the plural noun \"writings,\" not the singular possessive noun \"writing’s.\" Choice D is incorrect because the context requires the singular possessive noun \"author’s\" and the plural noun \"writings,\" not the plural possessive nouns \"authors’\" and \"writings’.\"",
    "source_id": "819c443d",
    "source_number": 73,
    "authored_distractors": false
  },
  {
    "id": "32bbf4e0-9618-5cc8-9677-8817c792a990",
    "external_key": "SAT_RW:82a76537",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "MEDIUM",
    "prompt": "Key-value pairs are an important aspect of JavaScript Object Notation (JSON), an electronic file format for storing and transmitting data. Keys function as labels, while values contain the actual information. In a JSON file storing data about fire belly ______ instance, you could encounter a key such as “species” with the associated value of “*Cynops orientalis*.”\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "217c6411-5d48-3a6d-8166-8b09722f888b",
        "key": "A",
        "text": "newts. For"
      },
      {
        "id": "b89e2faf-3e9b-3daf-bbec-84fbaa83bc3f",
        "key": "B",
        "text": "newts, for"
      },
      {
        "id": "fca5a555-cd7f-37c8-99fe-a42eefa481a2",
        "key": "C",
        "text": "newts: for"
      },
      {
        "id": "6bd52be4-33cb-3fec-af2a-06fd1846de4b",
        "key": "D",
        "text": "newts; for"
      }
    ],
    "correct_option_id": "b89e2faf-3e9b-3daf-bbec-84fbaa83bc3f",
    "explanation": "Choice B is the best answer. The convention being tested is the use of punctuation within a sentence. The comma after “newts” pairs with the comma after “instance” to separate the supplementary element “for instance” from the rest of the sentence. The supplementary element appears between the prepositional phrase (“In…newts”) and the main clause of the sentence (“you…orientalis”) and signals that the sentence is presenting an example of how keys and values function in JSON files.\n\nChoice A is incorrect because it results in a sentence fragment (“In a JSON file storing data about fire belly newts”). Choice C is incorrect because a colon can’t be paired with a comma in this way to separate the supplementary element “for instance” from the rest of the sentence. Choice D is incorrect because a semicolon can’t be paired with a comma in this way to separate the supplementary element “for instance” from the rest of the sentence.",
    "source_id": "82a76537",
    "source_number": 74,
    "authored_distractors": false
  },
  {
    "id": "4d645e43-3b0b-5b86-9e8d-5f65b162ffb2",
    "external_key": "SAT_RW:e2f77ae7",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "MEDIUM",
    "prompt": "That Chaucer’s *Canterbury Tales* inspired imitators is evident from the existence of three near-contemporary “continuations” of the collection: *The Siege of Thebes*, which purports to be a new tale told during the pilgrims’ ______ *The Tale of Beryn*, which depicts the pilgrims as tourists; and *The Ploughman’s Tale*, which features a minor character from the original work.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "f5ce1491-ea52-3712-b366-d92543cc2f32",
        "key": "A",
        "text": "return."
      },
      {
        "id": "fb460891-8fff-388a-83ea-792065332724",
        "key": "B",
        "text": "return"
      },
      {
        "id": "88e71664-9afa-3f79-96dc-5fe8481f8b5d",
        "key": "C",
        "text": "return;"
      },
      {
        "id": "6a32531b-c281-34b4-8e3f-29b00dccbf46",
        "key": "D",
        "text": "return,"
      }
    ],
    "correct_option_id": "88e71664-9afa-3f79-96dc-5fe8481f8b5d",
    "explanation": "Choice C is the best answer. The convention being tested is the punctuation of elements in a complex series. It’s conventional to use a semicolon to separate items in a complex series with internal punctuation, and in this choice, the semicolon after “return” is conventionally used to separate the first item (“The Siege of Thebes...return”) and the second item (“The Tale of Beryn...tourists”) in the series of tales. Moreover, the semicolon after “return” matches the semicolon used later to separate the second item and the third item (“and The Ploughman’s Tale...work”) in the series.\n\nChoice A is incorrect because placing a period after “return” results in a rhetorically unacceptable sentence fragment beginning with “The Tale of Beryn.” Choice B is incorrect because it fails to use appropriate punctuation to separate the first item and the second item in the complex series. Choice D is incorrect because a comma after “return” doesn’t match the semicolon used later to separate the second and third items in the series.",
    "source_id": "e2f77ae7",
    "source_number": 75,
    "authored_distractors": false
  },
  {
    "id": "61959452-1548-5ddc-a4af-bf6b271fab87",
    "external_key": "SAT_RW:ac5536c1",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "MEDIUM",
    "prompt": "Beatrix Potter is perhaps best known for writing and illustrating children’s books such as *The Tale of Peter Rabbit* (1902), but she also dedicated herself to mycology, the study of ______ more than 350 paintings of the fungal species she observed in nature and submitting her research on spore germination to the Linnean Society of London.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "67b51c3b-b4c4-3668-aeb9-3f2ef5156f3e",
        "key": "A",
        "text": "fungi; producing"
      },
      {
        "id": "07a685bb-2e80-30bc-ab0f-e32c80952a1d",
        "key": "B",
        "text": "fungi. Producing"
      },
      {
        "id": "baaa6b2c-20d1-3c4b-97ca-897ab2f2137e",
        "key": "C",
        "text": "fungi producing"
      },
      {
        "id": "7e627ab0-ed88-30c4-bfd6-a71578fbcef7",
        "key": "D",
        "text": "fungi, producing"
      }
    ],
    "correct_option_id": "7e627ab0-ed88-30c4-bfd6-a71578fbcef7",
    "explanation": "Choice D is the best answer. The convention being tested is punctuation use between two supplementary phrases following the coordinate clause (“but she…mycology”). This choice correctly uses a comma to mark the boundary between the supplementary noun phrase (“the study of fungi”) that defines the term “mycology” and the supplementary participial phrase (“producing...London”) that provides additional information about the extent to which Potter dedicated herself to mycology.\n\nChoice A is incorrect because a semicolon can’t be used in this way to join two supplementary phrases following a coordinate clause. Choice B is incorrect because it results in a rhetorically unacceptable sentence fragment beginning with “producing.” Choice C is incorrect. The lack of punctuation results in a sentence that illogically suggests that the study of fungi is producing more than 350 paintings.",
    "source_id": "ac5536c1",
    "source_number": 76,
    "authored_distractors": false
  },
  {
    "id": "ca4179aa-35d7-58a4-8aec-e7e218597272",
    "external_key": "SAT_RW:a153ad6a",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "MEDIUM",
    "prompt": "While light is known as one of the fastest-moving substances, it slows down when passing through some types of matter. One such type of matter is a form of cooled, condensed gas called a Bose-Einstein condensate ______ Dutch physicist Lene Hau famously used a BEC to slow a beam of light to a complete halt.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "4c9918fb-0ee8-384a-b364-776e82264289",
        "key": "A",
        "text": "(BEC),"
      },
      {
        "id": "fb7a54b9-ffeb-31d7-a6f3-1df418f4e730",
        "key": "B",
        "text": "(BEC) and"
      },
      {
        "id": "5d335fce-0dad-3da6-8868-4c956d38c17e",
        "key": "C",
        "text": "(BEC);"
      },
      {
        "id": "95d08051-82c6-349c-9fc1-8a6adcbf0cea",
        "key": "D",
        "text": "(BEC)"
      }
    ],
    "correct_option_id": "5d335fce-0dad-3da6-8868-4c956d38c17e",
    "explanation": "Choice C is the best answer. The convention being tested is the coordination of main clauses within a sentence. This choice correctly uses a semicolon to join the first main clause (\"One…(BEC)\") and the second main clause (\"Dutch…halt\").\n\nChoice A is incorrect because it results in a comma splice. Without a conjunction following it, a comma can’t be used in this way to join two main clauses. Choice B is incorrect because it results in a run-on sentence. Without a comma preceding it, a conjunction can’t be used in this way to join two main clauses. Choice D is incorrect because it results in a run-on sentence. The two main clauses are fused without punctuation and/or a conjunction.",
    "source_id": "a153ad6a",
    "source_number": 77,
    "authored_distractors": false
  },
  {
    "id": "8304f365-5136-5e37-a0f9-40c80cdb062f",
    "external_key": "SAT_RW:9eb43963",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "MEDIUM",
    "prompt": "Water in the North Atlantic Ocean is pushed eastward by powerful winds, but the rotation of Earth and interference from nearby landmasses together cause ______ to swirl into a massive, churning whirlpool—also called the North Atlantic Gyre—that spins clockwise.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "5af21e89-a159-3e11-b1b4-4792c8eee0ea",
        "key": "A",
        "text": "these"
      },
      {
        "id": "94d46b14-6649-3a2b-84b5-f6f301c2b87a",
        "key": "B",
        "text": "those"
      },
      {
        "id": "0bc050c4-50c5-316f-96dc-fe0a3368eba2",
        "key": "C",
        "text": "them"
      },
      {
        "id": "1af8ccf8-4670-3fab-9790-3c7b3dbc9c9a",
        "key": "D",
        "text": "it"
      }
    ],
    "correct_option_id": "1af8ccf8-4670-3fab-9790-3c7b3dbc9c9a",
    "explanation": "Choice D is the best answer. The convention being tested is pronoun-antecedent agreement. The singular pronoun \"it\" agrees in number with the singular antecedent \"water\" and clearly indicates that the water swirls into a whirlpool.\n\nChoice A is incorrect. The plural pronoun \"these\" neither agrees in number with the singular antecedent \"water\" nor clearly indicates that the water—not another plural noun in the sentence, such as \"landmasses\" or \"winds\"—swirls into a whirlpool. Choice B is incorrect. The plural pronoun \"those\" neither agrees in number with the singular antecedent \"water\" nor clearly indicates that the water—not another plural noun in the sentence, such as \"landmasses\" or \"winds\"—swirls into a whirlpool. Choice C is incorrect. The plural pronoun \"them\" neither agrees in number with the singular antecedent \"water\" nor clearly indicates that the water—not another plural noun in the sentence, such as \"landmasses\" or \"winds\"—swirls into a whirlpool.",
    "source_id": "9eb43963",
    "source_number": 78,
    "authored_distractors": false
  },
  {
    "id": "2949a02d-2b66-5e30-ba4a-a59aa881d55c",
    "external_key": "SAT_RW:eeb14722",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "MEDIUM",
    "prompt": "The soundtrack to Mira Nair’s 1991 film *Mississippi Masala* expressively captures the clashing of cultures that happens when ______ (a young Indian woman from Uganda and a young African American man from Mississippi) meet. Featured throughout the film are songs from Uganda’s Afrigo Band, the Indian composer L. Subramaniam, and the Mississippi blues musician Sam Chatmon.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "7a3911cd-f4cf-35fa-8351-17f4a4cd0d8d",
        "key": "A",
        "text": "it’s two protagonists"
      },
      {
        "id": "f63b8cf8-3775-38ec-863d-ed9b008b57e1",
        "key": "B",
        "text": "its two protagonist’s"
      },
      {
        "id": "5af52930-f74d-33b8-ae97-41e6a3160c0e",
        "key": "C",
        "text": "it’s two protagonist’s"
      },
      {
        "id": "6a22de3b-f8e5-3dbb-8bc2-ddb434a0a5dc",
        "key": "D",
        "text": "its two protagonists"
      }
    ],
    "correct_option_id": "6a22de3b-f8e5-3dbb-8bc2-ddb434a0a5dc",
    "explanation": "Choice D is the best answer. The conventions being tested are the use of possessive determiners and the use of plural nouns. The singular possessive determiner \"its\"—which agrees in number with the singular noun phrase \"Mira Nair’s 1991 film Mississippi Masala\"—and the plural noun \"protagonists\" correctly indicate that Nair’s film has multiple protagonists.\n\nChoice A is incorrect because \"it’s\" is the contraction for \"it is,\" not a possessive determiner. Choice B is incorrect because the context requires the plural noun \"protagonists,\" not the singular possessive noun \"protagonist’s.\" Choice C is incorrect because the context requires the possessive determiner \"its\" and the plural noun \"protagonists,\" not the contraction \"it’s\" or the singular possessive noun \"protagonist’s.\"",
    "source_id": "eeb14722",
    "source_number": 79,
    "authored_distractors": false
  },
  {
    "id": "52a6b56d-ef0d-5e2e-a7d3-c7bd30169686",
    "external_key": "SAT_RW:20ea68b7",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "MEDIUM",
    "prompt": "It can take time for proposed amendments to the US Constitution to become law. For example, the Twenty-Second Amendment, which limits the number of ______ can serve, was first proposed in 1947 but wasn’t approved by the required three-fourths majority of state legislatures until 1951.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "c3585dd0-edec-334b-9ad9-c31de228bf66",
        "key": "A",
        "text": "terms presidents"
      },
      {
        "id": "6516e450-8971-3d2f-aafa-135ef86b97fd",
        "key": "B",
        "text": "term’s presidents"
      },
      {
        "id": "27460153-b708-3043-ad1f-7a22f16ac09c",
        "key": "C",
        "text": "term’s president’s"
      },
      {
        "id": "f241060e-8c11-38b7-a37c-06e019166241",
        "key": "D",
        "text": "terms president’s"
      }
    ],
    "correct_option_id": "c3585dd0-edec-334b-9ad9-c31de228bf66",
    "explanation": "Choice A is the best answer. The convention being tested is the use of plural nouns. The plural nouns \"terms\" and \"presidents\" correctly indicate that the amendment involves multiple terms and applies to presidents in general.\n\nChoice B is incorrect because the context requires the plural noun \"terms,\" not the singular possessive noun \"term’s.\" Choice C is incorrect because the context requires the plural nouns \"terms\" and \"presidents,\" not the singular possessive nouns \"term’s\" and \"president’s.\" Choice D is incorrect because the context requires the plural noun \"presidents,\" not the singular possessive noun \"president’s.\"",
    "source_id": "20ea68b7",
    "source_number": 80,
    "authored_distractors": false
  },
  {
    "id": "7bf61391-1605-5e95-8259-6bc97046ff8b",
    "external_key": "SAT_RW:3543e6e2",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "EASY",
    "prompt": "The following text is from Jane Austen’s 1811 novel *Sense and Sensibility*. Elinor lives with her younger sisters and her mother, Mrs. Dashwood.\n\n> Elinor, this eldest daughter, whose advice was so effectual, possessed a strength of understanding, and coolness of judgment, which qualified her, though only nineteen, to be the counsellor of her mother, and enabled her frequently to counteract, to the advantage of them all, that eagerness of mind in Mrs. Dashwood which must generally have led to imprudence. She had an excellent heart;—her disposition was affectionate, and her feelings were strong; but she knew how to govern them: it was a knowledge which her mother had yet to learn; and which one of her sisters had resolved never to be taught.\n\nAccording to the text, what is true about Elinor?",
    "options": [
      {
        "id": "d6e9d16f-d2c5-3ec6-8502-d64c29a73261",
        "key": "A",
        "text": "Elinor often argues with her mother but fails to change her mind."
      },
      {
        "id": "c7a0a7ad-381f-3216-83cd-b18cd7a9ddd7",
        "key": "B",
        "text": "Elinor can be overly sensitive with regard to family matters."
      },
      {
        "id": "10414492-b289-3db5-b0ed-0e2c5d339668",
        "key": "C",
        "text": "Elinor thinks her mother is a bad role model."
      },
      {
        "id": "1d90e5b4-03ee-3a97-a630-dcd3efe4660d",
        "key": "D",
        "text": "Elinor is remarkably mature for her age."
      }
    ],
    "correct_option_id": "1d90e5b4-03ee-3a97-a630-dcd3efe4660d",
    "explanation": "Choice D is the best answer because it provides a detail about Elinor that is established in the text. The text indicates that although Elinor is “only nineteen,” she gives good advice and exhibits such a high level of understanding and judgment that she serves as “the counsellor of her mother.” Thus, Elinor is mature beyond her years.\n\nChoice A is incorrect because it isn’t supported by the text: although the text says that Elinor advises her mother and often counteracts her mother’s impulses, there’s no mention of Elinor arguing with her mother or failing to change her mother’s mind. Choice B is incorrect because it isn’t supported by the text: although the text mentions that Elinor has strong feelings, it doesn’t indicate that she’s excessively sensitive when it comes to family issues. Choice C is incorrect because it isn’t supported by the text: there’s no mention of what Elinor thinks about her mother and no suggestion that she thinks her mother is a bad role model. Because she’s described as having “an excellent heart,” Elinor likely doesn’t think ill of her mother.",
    "source_id": "3543e6e2",
    "source_number": 81,
    "authored_distractors": false
  },
  {
    "id": "66e4d22f-6369-5519-8196-7cde035faa7b",
    "external_key": "SAT_RW:75e07a4d",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "EASY",
    "prompt": "**Sample of Food Items from Gemini Mission Menus**\n\n| Food item | Day | Meal |\n| :--- | :---: | :---: |\n| Sugar cookie cubes | 1 | B |\n| Chicken and vegetables | 2 | B |\n| Shrimp cocktail | 4 | C |\n| Hot cocoa | 3 | A |\n\nTo make sure they got the nutrition they needed while in space, the astronauts of NASA’s Gemini missions were given menus for three meals a day (meals A, B, and C) on a four-day rotating schedule. Looking at the sample of food items from these menus, a student notes that on day 1, the menu included ______\n\nWhich choice most effectively uses data from the table to complete the statement?",
    "options": [
      {
        "id": "186386cd-6f12-3e62-a891-c671fa76c4b2",
        "key": "A",
        "text": "shrimp cocktail for meal B."
      },
      {
        "id": "3472ef52-954c-35af-a787-bae892f31226",
        "key": "B",
        "text": "hot cocoa for meal C."
      },
      {
        "id": "7eb1ffeb-49c3-3dbe-8cc7-03c7326f4d25",
        "key": "C",
        "text": "sugar cookie cubes for meal B."
      },
      {
        "id": "d558c7ef-9843-3ac8-88d1-c1f830662605",
        "key": "D",
        "text": "chicken and vegetables for meal A."
      }
    ],
    "correct_option_id": "7eb1ffeb-49c3-3dbe-8cc7-03c7326f4d25",
    "explanation": "Choice C is the best answer because it most effectively uses data from the table to complete the statement. The table shows that on day 1, the menu for NASA’s Gemini missions included sugar cookie cubes for meal B.\n\nChoice A is incorrect because according to the table, shrimp cocktail was served on day 4, not day 1; moreover, the item was served for meal C, not meal B, as this choice claims. Choice B is incorrect because according to the table, hot cocoa was served on day 3, not on day 1; moreover, the item was served for meal A, not for meal C, as this choice claims. Choice D is incorrect because according to the table, chicken and vegetables were served on day 2, not on day 1; moreover, the item was served for meal B, not for meal A, as this choice claims.",
    "source_id": "75e07a4d",
    "source_number": 82,
    "authored_distractors": false
  },
  {
    "id": "bed622f3-1fbc-5813-a965-47f6a0eb2bc9",
    "external_key": "SAT_RW:cf956802",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "EASY",
    "prompt": "When fashion designer Lloyd Henri Kiva New opened his store in Scottsdale, Arizona, in 1945, he quickly became known for creating delicately crafted leather goods, like belts and hats. He was perhaps most renowned for his colorful handbags, which he made by hand using a long and painstaking process. As he gained more customers, New began using sewing machines and other tools to help him produce bags more efficiently, though he continued to handcraft the crucial details that made each bag unique.\n\nBased on the text, what would have been the most likely consequence if New had not begun using sewing machines?",
    "options": [
      {
        "id": "7d22deb1-ca8f-3fc3-8e12-f06e3516b882",
        "key": "A",
        "text": "He would have been unable to ensure that each bag included unique, handcrafted details."
      },
      {
        "id": "a5a79272-a7a5-328a-9d43-4d9401a4e7ef",
        "key": "B",
        "text": "He would have struggled to meet the increasing demand for his bags."
      },
      {
        "id": "114e94f7-9dd8-33e8-809f-2722784e960f",
        "key": "C",
        "text": "He would have had to individually design each bag he produced."
      },
      {
        "id": "dd3b6684-bc5a-3a4c-a211-0574a3ddfc44",
        "key": "D",
        "text": "He would not have been able to generate as much interest in his bags."
      }
    ],
    "correct_option_id": "a5a79272-a7a5-328a-9d43-4d9401a4e7ef",
    "explanation": "Choice B is the best answer because it presents the most likely consequence if New had not begun using sewing machines. The text states that New gained new customers and that sewing machines allowed him to make bags more efficiently, or in less time than he could when sewing by hand. It’s reasonable to conclude that if New hadn’t reduced the time it took to make each bag by starting to use sewing machines, it would have been hard for him to keep up with the increased demand.\n\nChoice A is incorrect because the text indicates that New added unique, handcrafted details to his bags before he started using sewing machines and continued to do so after he started using them. Choice C is incorrect because the text doesn’t suggest that individually designing each bag would have been a consequence of not using sewing machines, since New was already designing unique details for each bag before he started using sewing machines and continued to do so after he started using them. Choice D is incorrect because the text indicates that people were already interested in New’s bags before he started using sewing machines. Rather than allowing New to generate more interest in his bags, sewing machines helped New keep up with the interest that had already grown.",
    "source_id": "cf956802",
    "source_number": 83,
    "authored_distractors": false
  },
  {
    "id": "bd35cd8c-296f-5c5f-8963-d43def6673c1",
    "external_key": "SAT_RW:3091f805",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "EASY",
    "prompt": "Ochre sea stars live in tidal pools along the shoreline of the Pacific Ocean. At night, they move to higher shore levels in search of prey. But scientists Corey Garza and Carlos Robles noticed that ochre sea stars stayed at lower levels at night after heavy rains. Garza and Robles hypothesized that a layer of fresh water formed by rainfall was a barrier to the sea stars. To test their hypothesis, the scientists did an experiment. They placed some sea stars in a climbable tank of seawater and other sea stars in a similar tank of seawater with a layer of fresh water on top. Then, the scientists watched the sea stars’ behavior at night.\n\nWhich finding from the experiment, if true, would most directly support Garza and Robles’s hypothesis?",
    "options": [
      {
        "id": "dc69e7be-3c9f-3660-a21e-436a79c6cfb3",
        "key": "A",
        "text": "None of the sea stars climbed to the tops of the tanks, but sea stars in the tank with only seawater moved around the bottom of the tank more than sea stars in the other tank did."
      },
      {
        "id": "026b7526-1c46-3a7d-8749-83e1c5cca5a6",
        "key": "B",
        "text": "Sea stars in the tank with only seawater climbed to the top of the tank, but sea stars in the other tank stopped climbing just below the layer of fresh water."
      },
      {
        "id": "8e0612aa-beeb-3fbd-8ef2-5fad6beed6cb",
        "key": "C",
        "text": "Both groups of sea stars climbed to the tops of the tanks, but sea stars in the tank with only seawater climbed more slowly than sea stars in the other tank did."
      },
      {
        "id": "28fc64ac-5671-34eb-99b9-dc84e594949b",
        "key": "D",
        "text": "Sea stars in the tank with only seawater mostly stayed near the bottom of the tank, but sea stars in the other tank climbed into the layer of fresh water."
      }
    ],
    "correct_option_id": "026b7526-1c46-3a7d-8749-83e1c5cca5a6",
    "explanation": "Choice B is the best answer because it presents a finding that, if true, would support Garza and Robles’s hypothesis that a layer of fresh water forms a barrier to ochre sea stars. The text explains that the sea stars tend to move to higher shore levels at night in search of prey, but after a heavy rain, the sea stars stay at lower shore levels. Garza and Robles hypothesize that rainfall results in a layer of fresh water that the sea stars don’t cross. To determine whether fresh water forms a barrier to sea stars, Garza and Robles observed how sea stars behaved in a tank of only seawater and in a tank of seawater with a layer of fresh water on top. If the sea stars climbed to the top of the tank with only seawater but stopped climbing just below the layer of fresh water in the other tank, that would suggest that fresh water does indeed serve as a barrier to the sea stars, thereby supporting Garza and Robles’s hypothesis.\n\nChoice A is incorrect because finding that sea stars in the tank with only seawater moved around the bottom of the tank more than sea stars in the other tank did but that none of the stars in either tank climbed to the top would be irrelevant to Garza and Robles’s hypothesis. Such a finding would reveal nothing about whether fresh water serves as a barrier to sea stars. Choice C is incorrect because finding that sea stars climbed to the top of both tanks would weaken, not support, Garza and Robles’s hypothesis, since it would indicate that the layer of fresh water wasn’t a barrier to the sea stars. Choice D is incorrect because finding that sea stars in the tank with only seawater mostly stayed near the bottom of the tank but sea stars in the other tank climbed into the layer of fresh water wouldn’t support Garza and Robles’s hypothesis. Instead, such a finding would suggest that the layer of fresh water wasn’t a barrier to the sea stars, thereby weakening Garza and Robles’s hypothesis.",
    "source_id": "3091f805",
    "source_number": 84,
    "authored_distractors": false
  },
  {
    "id": "ede48599-5015-5699-8728-8b000da4752b",
    "external_key": "SAT_RW:0147b080",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "EASY",
    "prompt": "**Pyramids in Egypt and the Americas**\n\n| Pyramid | Country | Height (meters) | Age (years before present) |\n| :--- | :--- | :---: | :---: |\n| The Great Pyramid | Mexico | 33 | 2,050 to 2,400 |\n| The Pyramid of Djoser | Egypt | 60 | 4,600 to 4,700 |\n| The Pyramid of Sahure | Egypt | 47 | 4,400 to 4,500 |\n| El Castillo | Belize | 40 | 1,100 to 1,400 |\n\nA student is writing an essay about four pyramids for a history class and wants to note how long ago each pyramid was built and how tall each pyramid is. Consulting the table, the student finds that el Castillo was built 1,100 to 1,400 years ago and is ______\n\nWhich choice most effectively uses data from the table to complete the text?",
    "options": [
      {
        "id": "629f34bd-a69d-37b1-8726-c8c7f41f7b47",
        "key": "A",
        "text": "33 meters tall."
      },
      {
        "id": "d471c85c-794d-3545-b33c-41106c0f8056",
        "key": "B",
        "text": "47 meters tall."
      },
      {
        "id": "9a3a6b99-6cae-34f3-9c1c-f795e2d79516",
        "key": "C",
        "text": "40 meters tall."
      },
      {
        "id": "1ed8ff44-cb54-377c-b11d-b2a2cba57620",
        "key": "D",
        "text": "60 meters tall."
      }
    ],
    "correct_option_id": "9a3a6b99-6cae-34f3-9c1c-f795e2d79516",
    "explanation": "Choice C is the best answer because it most effectively uses data from the table to complete the text about the el Castillo pyramid. The table presents information for the location, height, and age of four pyramids, and the task is to use the data from the table to complete the text by choosing the correct height for el Castillo, which the table shows is 40 meters.\n\nChoice A is incorrect because, according to the table, el Castillo is 40 meters tall, not 33 meters, which is the height of the Great Pyramid in Mexico. Choice B is incorrect because, according to the table, el Castillo is 40 meters tall, not 47 meters, which is the height of the Pyramid of Sahure in Egypt. Choice D is incorrect because, according to the table, el Castillo is 40 meters tall, not 60 meters, which is the height of the Pyramid of Djoser in Egypt.",
    "source_id": "0147b080",
    "source_number": 85,
    "authored_distractors": false
  },
  {
    "id": "36c60e48-9dfb-53e9-a225-b358947bd3a2",
    "external_key": "SAT_RW:714e4c10",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "EASY",
    "prompt": "Ruth Asawa was an accomplished artist who worked in many art forms, including her unique tied-wire sculptures, but she was dedicated to more than the creation of art. Asawa also wanted to bring art to children in her hometown of San Francisco, California. To that end, in 1968 she cofounded the Alvarado School Arts Workshop, which brought works of art and artists into public schools, and in 1982 she helped found a San Francisco public arts high school, which was later named after her.\n\nWhich choice best states the main idea of the text?",
    "options": [
      {
        "id": "b5c5538e-ae19-3685-8ffe-447b0262e677",
        "key": "A",
        "text": "Asawa inspired many other artists to share their work with students in public schools."
      },
      {
        "id": "32ad32d9-645a-3064-8f19-c9c632b298d2",
        "key": "B",
        "text": "Asawa’s unique sculptures were appreciated more by local art communities than they were nationwide."
      },
      {
        "id": "e4e6a604-2909-3a5f-8b36-85f3de64ab7f",
        "key": "C",
        "text": "Asawa’s interest in art education prompted her to create art programs for students in San Francisco."
      },
      {
        "id": "7fde6c78-f29e-3744-8219-9be4af54aa2f",
        "key": "D",
        "text": "Asawa left a promising career as a sculptor to work as an art teacher in San Francisco schools."
      }
    ],
    "correct_option_id": "e4e6a604-2909-3a5f-8b36-85f3de64ab7f",
    "explanation": "Choice C is the best answer because it most accurately states the main idea of the text. The text begins by establishing Ruth Asawa as an artist who worked in several art forms but emphasizes that she was interested in art for reasons other than her desire to create it. The text mentions two ways in which Asawa brought art to children through public schools: cofounding the Alvarado School Arts Workshop in 1968 and helping found a public arts high school in 1982. Thus, the main idea is that Asawa’s interest in art education motivated her to establish arts programs for students in San Francisco.\n\nChoice A is incorrect because the text doesn’t mention Asawa inspiring other artists to share their work with students. While the text does note that the Alvarado School Arts Workshop brought works of art and artists into public schools, it doesn’t state that Asawa motivated these artists. Choice B is incorrect because the text makes no comparison between local and national appreciation of Asawa’s sculptures. While the text does mention that Asawa created unique tied-wire sculptures and was connected to San Francisco, it does not contrast her local and national critical receptions. Choice D is incorrect. Although the text emphasizes Asawa’s educational initiatives, it doesn’t state or imply that she abandoned her career as a sculptor to work as an art teacher. Instead, the text portrays her educational work as a complement to her career as a successful artist.",
    "source_id": "714e4c10",
    "source_number": 86,
    "authored_distractors": false
  },
  {
    "id": "745c8967-9470-520e-9fe8-08e3ec85f600",
    "external_key": "SAT_RW:7a1877be",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "EASY",
    "prompt": "**Nucleobase Concentrations from Murchison Meteorite and Soil Samples in Parts per Billion**\n\n| Nucleobase | Murchison meteorite sample 1 | Murchison meteorite sample 2 | Murchison soil sample |\n| :--- | :---: | :---: | :---: |\n| Isoguanine | 0.5 | 0.04 | not detected |\n| Purine | 0.2 | 0.02 | not detected |\n| Xanthine | 39 | 3 | 1 |\n| Adenine | 15 | 1 | 40 |\n| Hypoxanthine | 24 | 1 | 2 |\n\nEmploying high-performance liquid chromatography—a process that uses pressurized water to separate material into its component molecules—astrochemist Yashiro Oba and colleagues analyzed two samples of the Murchison meteorite that landed in Australia as well as soil from the landing zone of the meteorite to determine the concentrations of various organic molecules. By comparing the relative concentrations of types of molecules known as nucleobases in the Murchison meteorite with those in the soil, the team concluded that there is evidence that the nucleobases in the Murchison meteorite formed in space and are not the result of contamination on Earth.\n\nWhich choice best describes data from the table that support the team’s conclusion?",
    "options": [
      {
        "id": "71a17793-aed5-3452-b77a-003e7693dad9",
        "key": "A",
        "text": "Isoguanine and purine were detected in both meteorite samples but not in the soil sample."
      },
      {
        "id": "76046316-7f8e-3012-b59a-659d8bfe2e06",
        "key": "B",
        "text": "Adenine and xanthine were detected in both of the meteorite samples and in the soil sample."
      },
      {
        "id": "b0015666-5b23-39d4-9fc7-6c4f3018efed",
        "key": "C",
        "text": "Hypoxanthine and purine were detected in both the Murchison meteorite sample 2 and in the soil sample."
      },
      {
        "id": "e4f53bc3-301c-306a-9863-766dea6d4093",
        "key": "D",
        "text": "Isoguanine and hypoxanthine were detected in the Murchison meteorite sample 1 but not in sample 2."
      }
    ],
    "correct_option_id": "71a17793-aed5-3452-b77a-003e7693dad9",
    "explanation": "Choice A is the best answer. The researchers concluded that the meteorite’s nucleobases weren’t the result of soil contamination. Presence of nucleobases in the meteorite and not in soil provides evidence that those nucleobases likely didn’t come from the soil.\n\nChoice B is incorrect. This choice doesn’t justify the conclusion. The researchers concluded that the meteorite’s nucleobases weren’t the result of soil contamination. If the nucleobases are present in both the soil and meteorite, then it’s possible that these nucleobases came from the soil. Choice C is incorrect. This choice misreads the table. Purine was not detected in the soil sample. Choice D is incorrect. This choice misreads the table. Both isoguanine and hypoxanthine were detected in both Murchison meteorite samples.",
    "source_id": "7a1877be",
    "source_number": 87,
    "authored_distractors": false
  },
  {
    "id": "3983fa84-ea41-5d04-8a0b-437e080386e2",
    "external_key": "SAT_RW:57485f5e",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "EASY",
    "prompt": "The following text is adapted from Johanna Spyri’s 1881 novel *Heidi* (translated by Elisabeth Stork in 1915). Eight-year-old Heidi and her friend’s grandmother are looking at some illustrated books.\n\n> Heidi had come and was looking with wondering eyes at the splendid pictures in the large books, that Grandmama was showing her. Suddenly she screamed aloud, for there on the picture she saw a peaceful flock grazing on a green pasture. In the middle a shepherd was standing, leaning on his crook. The setting sun was shedding a golden light over everything. With glowing eyes Heidi devoured the scene.\n\nWhich choice best states the main idea of the text?",
    "options": [
      {
        "id": "0ff2b07c-7644-3c12-93d9-a452ed7719c2",
        "key": "A",
        "text": "Heidi is upset until she sees a serene image of a pasture in one of Grandmama’s books."
      },
      {
        "id": "c87400bb-858c-38f5-81b1-804d082ae799",
        "key": "B",
        "text": "Heidi is delighted and fascinated by an image she sees in one of Grandmama’s books."
      },
      {
        "id": "4aa41756-e169-3abe-a656-59272c84720b",
        "key": "C",
        "text": "Heidi is initially frightened by an image in one of Grandmama’s books but quickly comes to appreciate its beauty."
      },
      {
        "id": "2f0507a7-de74-3607-979d-e33c4578ba40",
        "key": "D",
        "text": "Heidi is inspecting an image in one of Grandmama’s books because she has never seen a shepherd with his sheep before."
      }
    ],
    "correct_option_id": "c87400bb-858c-38f5-81b1-804d082ae799",
    "explanation": "Choice B is the best answer because it most effectively states the main idea of the text, which is that Heidi is delighted and fascinated by an image she sees in one of Grandmama’s books. In the text, Heidi screams upon first seeing the picture of the green pasture. In another context, such a reaction might suggest fear, but here the reaction is followed by descriptions of an image that’s peaceful rather than scary. The text goes on to describe Heidi’s eyes as “glowing” and states that she “devoured the scene,” suggesting that the image delights and fascinates her so much that she wants to examine every detail. Together, these descriptions suggest that Heidi is thrilled and intrigued by the image in the book.\n\nChoice A is incorrect because there’s nothing in the text to suggest that Heidi is upset before seeing the peaceful image of the green pasture. Before Heidi sees that image, the text describes her as “looking with wondering eyes at the splendid pictures” in the book, suggesting that Heidi is intrigued, not that she’s unhappy. Choice C is incorrect. Although Heidi screams upon first seeing the image, the text’s description of the image and Heidi’s other reactions to it suggest that she is screaming with delight, not fear. The text describes the images in the book as “splendid” and the particular image that causes her to scream as peaceful rather than frightening. It also describes Heidi’s eyes as “glowing” and states that she “devoured the scene,” suggesting that the image delights and fascinates her so much that she wants to examine every detail. Choice D is incorrect because it’s unclear from the text whether Heidi has ever seen a shepherd with his sheep before. The text merely suggests that she is delighted and fascinated by the image of the shepherd and his sheep.",
    "source_id": "57485f5e",
    "source_number": 88,
    "authored_distractors": false
  },
  {
    "id": "20005223-e268-5d6f-9b20-c8866dd0b5dd",
    "external_key": "SAT_RW:e677fa6c",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_CENTRAL_IDEAS_DETAILS",
    "topic_name": "Information and Ideas / Central Ideas and Details",
    "difficulty": "EASY",
    "prompt": "The following text is adapted from Edgar Allan Poe’s 1849 story “Landor’s Cottage.”\n\n> During a pedestrian trip last summer, through one or two of the river counties of New York, I found myself, as the day declined, somewhat embarrassed about the road I was pursuing. The land undulated very remarkably; and my path, for the last hour, had wound about and about so confusedly, in its effort to keep in the valleys, that I no longer knew in what direction lay the sweet village of B——, where I had determined to stop for the night.\n\nWhich choice best states the main idea of the text?",
    "options": [
      {
        "id": "e8c0f702-5861-32ae-b5d7-9f4365a60475",
        "key": "A",
        "text": "The narrator remembers a trip he took and admits to getting lost."
      },
      {
        "id": "f5ff8e7c-392c-311f-8b1a-3912598906f5",
        "key": "B",
        "text": "The narrator recalls fond memories of a journey that he took through some beautiful river counties."
      },
      {
        "id": "66f0e680-b718-3439-8f20-553d7507be3c",
        "key": "C",
        "text": "The narrator describes what he saw during a long trip through a frequently visited location."
      },
      {
        "id": "38c38904-ba2f-3f59-9e0d-6aa11259fd49",
        "key": "D",
        "text": "The narrator explains the difficulties he encountered on a trip and how he overcame them."
      }
    ],
    "correct_option_id": "e8c0f702-5861-32ae-b5d7-9f4365a60475",
    "explanation": "Choice A is the best answer. The narrator is “embarrassed” about the route he took, which ends up leaving him lost and confused about how to get to his destination for the evening.\n\nChoice B is incorrect. This choice doesn’t match the passage. The narrator is embarrassed, rather than fond, and he doesn’t describe the beauty of the place. Choice C is incorrect. This choice doesn’t match the passage. We don’t know from this excerpt whether or not the narrator has visited this part of New York multiple times. Choice D is incorrect. This choice doesn’t match the passage. The narrator doesn’t explain how he overcame being lost in this excerpt.",
    "source_id": "e677fa6c",
    "source_number": 89,
    "authored_distractors": false
  },
  {
    "id": "c07f53d0-11e2-564a-bee9-4e617936a1af",
    "external_key": "SAT_RW:d6e97054",
    "discipline_code": "SAT_RW",
    "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
    "topic_name": "Information and Ideas / Command of Evidence",
    "difficulty": "EASY",
    "prompt": "**Four Studies of Food Choices in Various Contexts**\n\n| Location | Food choices related to... | Study population | Number of participants |\n| :--- | :--- | :--- | :---: |\n| Canada | sports | adults | 17 |\n| United States | school | children | 44 |\n| India | community | adolescents and adults | 94 |\n| Ghana and Kenya | food shops | adolescents | 142 |\n\nThe table shows information from four studies about food choices people make in different contexts. According to the table, the study with the smallest number of participants involved only adults, and the study with the greatest number of participants involved ______\n\nWhich choice most effectively uses data from the table to complete the text?",
    "options": [
      {
        "id": "0886b2ce-cd2f-353d-a436-0645c30acc92",
        "key": "A",
        "text": "only children."
      },
      {
        "id": "e61deb70-5b39-309e-ac74-e80399222344",
        "key": "B",
        "text": "both adolescents and adults."
      },
      {
        "id": "42879ab7-767f-38e7-93d7-4e287a4a318f",
        "key": "C",
        "text": "only adolescents."
      },
      {
        "id": "65afdd69-c4d6-3f67-96c0-42c16f427374",
        "key": "D",
        "text": "only adults."
      }
    ],
    "correct_option_id": "42879ab7-767f-38e7-93d7-4e287a4a318f",
    "explanation": "Choice C is the best answer because it most effectively uses data from the table to complete the text’s comparison of the studies about food choices. The table shows information from four studies about food choices, including each study’s location, the context of the food choices examined, the study population, and the number of participants. According to the table, the study with the greatest number of participants (142) was conducted in Ghana and Kenya and involved only adolescents.\n\nChoice A is incorrect because the table indicates that the study that involved only children was conducted in the United States and had 44 participants—not the greatest number of participants. According to the table, the study with the greatest number of participants (142) involved only adolescents. Choice B is incorrect because the table indicates that the study population that consisted of both adolescents and adults was the India study, which had 94 participants—not the greatest number of participants. According to the table, the study with the greatest number of participants (142) involved only adolescents. Choice D is incorrect because, according to the table and the text, the study that involved only adults was conducted in Canada and had 17 participants—the smallest, not the greatest, number of participants in the table.",
    "source_id": "d6e97054",
    "source_number": 90,
    "authored_distractors": false
  },
  {
    "id": "4b69cf94-23c8-5ba3-99a5-759692349041",
    "external_key": "SAT_RW:95f037ad",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "The works of Chicana artist Ester Hernandez are now ______ in museums both in the United States and abroad, but the murals she contributed to as a member of Las Mujeres Muralistas early in her artistic career were displayed in outdoor public spaces across San Francisco.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "08326f95-cc50-3f24-96c9-c9c385f2cb7d",
        "key": "A",
        "text": "invented"
      },
      {
        "id": "593db34f-b1d6-3e7c-9b68-825e3a1c2fc9",
        "key": "B",
        "text": "adjusted"
      },
      {
        "id": "58a77576-6b4c-3edc-add9-8b0bb277c054",
        "key": "C",
        "text": "featured"
      },
      {
        "id": "78412808-f437-3b39-bb81-a2dd1323d3f4",
        "key": "D",
        "text": "recommended"
      }
    ],
    "correct_option_id": "58a77576-6b4c-3edc-add9-8b0bb277c054",
    "explanation": "Choice C is the best answer because it most logically completes the text’s discussion of Ester Hernandez’s art. In this context, \"featured\" means shown prominently. The text focuses on where Hernandez’s works have been and continue to be displayed, explaining that her early works, which consisted of murals, could be viewed in outdoor spaces in San Francisco. The central contrast developed in the text is between where her early works could be viewed and where her works can be viewed now, which is in museums across the United States and around the world. The context therefore supports the idea that Hernandez’s works are now shown, or featured, in museums globally.\n\nChoice A is incorrect because in this context \"invented\" would mean created something for the first time, which isn’t supported since the text doesn’t discuss where Hernandez creates her works or whether they’re original or innovative. Choice B is incorrect because \"adjusted\" in this context would mean adapted. Although the text mentions that many of Hernandez’s early works were outdoor murals and thus it may be reasonable to infer that Hernandez altered her approach to creating art so that her works could be displayed in indoor venues instead, the text makes no mention of how Hernandez’s works might have been adapted for such venues. The text focuses on where Hernandez’s works have been and continue to be displayed, not on how she or anyone else may have adapted, or adjusted, her works. Choice D is incorrect because \"recommended\" in this context would mean endorsed or put forth as a suggestion for something that is worth seeing. Although it may be reasonable to say that in choosing to display certain works, museum curators believe such works are worth seeing, the text doesn’t discuss the reasons why museums display Hernandez’s works. Instead, the text mainly develops a contrast between where Hernandez’s early works could once be viewed and where her work can be viewed now.",
    "source_id": "95f037ad",
    "source_number": 91,
    "authored_distractors": false
  },
  {
    "id": "e6f5e850-f7f2-5795-a905-8ec303a2a5b4",
    "external_key": "SAT_RW:e386a11d",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "*Cat and Plum Blossoms* is an important work of *Nihonga*, or classical Japanese painting. Unlike Kuroda Seiki, who adopted traditional European methods such as painting with oil on canvas, Hishida Shunsō ______ traditional Japanese approaches. For instance, Hishida produced *Cat and Plum Blossoms* by applying color pigments to a silk scroll.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "945de41a-d3e0-3289-b74c-2a9f9fbe7413",
        "key": "A",
        "text": "distrusted"
      },
      {
        "id": "96d24b8d-34ac-3fff-b26b-7050705bbe65",
        "key": "B",
        "text": "embraced"
      },
      {
        "id": "a3a0ef2f-de38-3ba1-bdea-294f935b6890",
        "key": "C",
        "text": "released"
      },
      {
        "id": "b8ac867f-05d9-3934-8960-a5548e92da0e",
        "key": "D",
        "text": "overlooked"
      }
    ],
    "correct_option_id": "96d24b8d-34ac-3fff-b26b-7050705bbe65",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion of Hishida Shunsō’s painting *Cat and Plum Blossoms*. In this context, \"embraced\" means accepted or adopted readily. The text begins by identifying *Cat and Plum Blossoms* as an example of *Nihonga*, or classical (that is, traditional) Japanese painting. The text continues by drawing a contrast between Hishida’s work and Kuroda Seiki’s work, which differs from that of Hishida in its use of the traditional European method of using oil paints on canvas rather than using traditional Japanese approaches. The text then concludes with an example of one such traditional Japanese painting technique exemplified by Hishida’s *Cat and Plum Blossoms*—applications of color pigments to a silk scroll—to further develop the contrast between the two artists’ approaches. This context supports the idea that Hishida adopted, or embraced, traditional Japanese approaches.\n\nChoice A is incorrect because in this context \"distrusted\" would mean that Hishida was skeptical of or lacked confidence in traditional Japanese approaches to painting. The text begins by stating that Hishida’s painting *Cat and Plum Blossoms* is an example of *Nihonga*, or traditional Japanese painting, and then cites Hishida’s application of color pigments to a silk scroll as an instance of a traditional Japanese painting technique. It therefore wouldn’t make sense to say that Hishida’s use of traditional Japanese painting techniques indicates his distrust, or skepticism, of them. Rather, it suggests that he embraced those techniques. Choice C is incorrect because saying that Hishida \"released\" traditional Japanese approaches to painting in this context would mean that he freed them from any restrictions. In using Hishida’s application of color pigments to a silk scroll in *Cat and Plum Blossoms* as an example of a traditional Japanese approach to painting found in *Nihonga*, the text strongly implies that Hishida followed these approaches, not that he removed them from any restrictions. Choice D is incorrect because in this context \"overlooked\" would mean ignored or failed to notice. The text establishes that Hishida’s painting *Cat and Plum Blossoms* is a notable work of *Nihonga*, or classical Japanese painting, that features the traditional technique of applying color pigments to a silk scroll. It wouldn’t make sense to say that Hishida’s use of a traditional Japanese approach to painting indicates that Hishida failed to notice those approaches.",
    "source_id": "e386a11d",
    "source_number": 92,
    "authored_distractors": false
  },
  {
    "id": "50619ac8-b9b1-51fd-a9b6-0f193fe4dd7b",
    "external_key": "SAT_RW:a1139ff8",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "In the 1990s, conservationists began planting more than 500,000 native trees in the habitat of the Azores bullfinch to boost the bird’s numbers. This approach was apparently ______: the Azores bullfinch’s population size increased from as few as 100 birds at the end of the 1980s to around 1,300 in 2023.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "aa6e081c-7f27-3720-9cf2-68873f71a920",
        "key": "A",
        "text": "amusing"
      },
      {
        "id": "70ed785e-f47a-3a12-811b-7b1aaec4717f",
        "key": "B",
        "text": "costly"
      },
      {
        "id": "06191e92-f08b-3a33-8e03-c53080050b41",
        "key": "C",
        "text": "successful"
      },
      {
        "id": "924efc21-fcd1-35b1-bf4b-1c7a2d7bf4e4",
        "key": "D",
        "text": "disastrous"
      }
    ],
    "correct_option_id": "06191e92-f08b-3a33-8e03-c53080050b41",
    "explanation": "Choice C is the best answer because it most logically completes the text’s discussion of the conservationists’ efforts to increase Azores bullfinch’s numbers. In this context, \"successful\" means accomplishing a goal or purpose. According to the text, conservationists planted more than 500,000 native trees in an Azores bullfinch habitat in order to boost the bird’s population size. The text then indicates that the population size did indeed grow as a result of the planted trees. Thus, in this context, the conservationists’ approach of planting native trees was successful because it achieved the goal of increasing the bird’s population size.\n\nChoice A is incorrect because the text gives no indication that the conservationists’ approach of planting native trees to increase Azores bullfinch’s numbers was \"amusing,\" or comical or entertaining. Instead, the approach was seriously undertaken and ultimately accomplished. Choice B is incorrect because the text doesn’t address how much it cost to achieve the goal of planting native trees to increase Azores bullfinch’s numbers. The text indicates that the approach was beneficial and successful rather than \"costly,\" or expensive or harmful. Choice D is incorrect. According to the text, the conservationists’ approach of planting native trees to increase Azores bullfinch’s numbers was beneficial and successful rather than \"disastrous,\" or damaging or unsuccessful.",
    "source_id": "a1139ff8",
    "source_number": 93,
    "authored_distractors": false
  },
  {
    "id": "7edb4b47-c382-5588-83d9-7a88e30d6f45",
    "external_key": "SAT_RW:97ab5669",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "Former astronaut Ellen Ochoa says that although she doesn’t have a definite idea of when it might happen, she ______ that humans will someday need to be able to live in other environments than those found on Earth. This conjecture informs her interest in future research missions to the moon.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "259d7136-730b-3b88-ab39-025853992203",
        "key": "A",
        "text": "demands"
      },
      {
        "id": "a233c6fd-cacc-3136-89fb-14984c6fb773",
        "key": "B",
        "text": "speculates"
      },
      {
        "id": "471b12a6-eb8a-304b-a35d-39f6d5a2c6cc",
        "key": "C",
        "text": "doubts"
      },
      {
        "id": "8a6bf74d-e084-300f-9b1c-cc913c4f9af5",
        "key": "D",
        "text": "establishes"
      }
    ],
    "correct_option_id": "a233c6fd-cacc-3136-89fb-14984c6fb773",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion of Ochoa’s prediction that humans will one day need to live in places other than Earth. As used in this context, “speculates” would mean puts forward an idea without firm evidence. The text states that Ochoa “doesn’t have a definite idea” about when humans might need to live in other environments and characterizes Ochoa’s prediction as a “conjecture,” or a conclusion presented without convincing evidence. This context indicates that Ochoa speculates when she makes this prediction.\n\nChoice A is incorrect because saying that Ochoa “demands,” or insists or requires, that humans will one day need to live in other environments than Earth’s would not make sense in context. The text indicates that she’s unsure about the timing but hypothesizes that it will someday happen. Choice C is incorrect because saying that Ochoa “doubts,” or questions or disbelieves, that humans will one day need to live in other environments than Earth’s would not make sense in context. The text indicates that although Ochoa is unsure about the timing, she hypothesizes that humans will need to live in places other than Earth and encourages research into future travel to the moon. Choice D is incorrect because saying that Ochoa “establishes,” or proves, that humans will one day need to live in other environments than Earth’s would not make sense in context. Rather than stating that Ochoa discusses her idea with certainty and supports it with evidence, the text indicates that Ochoa is unsure about when humans might need to live in other environments.",
    "source_id": "97ab5669",
    "source_number": 94,
    "authored_distractors": false
  },
  {
    "id": "983ed51e-c8a7-5825-b7b6-40c80d202d17",
    "external_key": "SAT_RW:a0777403",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "The following text is from Anita Desai’s 2011 novella *Translator Translated*. While working on her translation of a novel written in Odia (a language of India) into English, the narrator looks out her window at night to clear her mind.\n\n> I tried to distract myself with these sights of the ordinary world, but in my mind it was the lines I had been translating and the lines that I had been writing that remained in the forefront. I longed for sleep to obliterate them but it eluded me. Perhaps everything would be normal again once I had sent off the manuscript, I thought, and looked forward to completing the work.\n> \n> *©2011 by Anita Desai*\n\nAs used in the text, what does the word “completing” most nearly mean?",
    "options": [
      {
        "id": "9149ecb0-6a9a-3896-a4f0-54f9fb078716",
        "key": "A",
        "text": "Destroying"
      },
      {
        "id": "cb82510a-a249-3738-aa3b-db336c468b25",
        "key": "B",
        "text": "Finishing"
      },
      {
        "id": "c0ca2969-334a-3c20-b4f5-b799c722759e",
        "key": "C",
        "text": "Advertising"
      },
      {
        "id": "5793b2a5-ec1f-30ce-b92c-0d117f65ceec",
        "key": "D",
        "text": "Rejecting"
      }
    ],
    "correct_option_id": "cb82510a-a249-3738-aa3b-db336c468b25",
    "explanation": "Choice B is the best answer because as used in the text, \"completing\" most nearly means finishing. In the text, the narrator conveys that the task of translating a novel has been an all-consuming one and that she hopes things will \"be normal again\" once she has \"sent off the manuscript.\" In other words, the narrator is looking forward to finishing her work on the manuscript and returning to other things.\n\nChoice A is incorrect because in this context, \"completing\" doesn’t mean destroying, or ruining. The narrator addresses her desire to send off the manuscript she’s focused on and her hope that things will be \"normal again\" once she does, conveying that she is looking forward to finishing the work, not to ruining it. Choice C is incorrect because in this context, \"completing\" doesn’t mean advertising, or publicly promoting. The narrator addresses her complete focus on the translation and her hope that things will be \"normal again\" once she has \"sent off the manuscript,\" conveying that she is looking forward to finishing the task, not to promoting the resulting manuscript. Choice D is incorrect because in this context, \"completing\" doesn’t mean rejecting, or refusing or repelling. The narrator makes it clear that she is absorbed in working on the translation and plans to send off the manuscript, suggesting that instead of refusing to do the work, she is continuing to do it (even if she looks forward to things being \"normal again\" when she’s done).",
    "source_id": "a0777403",
    "source_number": 95,
    "authored_distractors": false
  },
  {
    "id": "79697204-f189-5bc3-958c-774e2e8f892d",
    "external_key": "SAT_RW:02fd3da7",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_CROSS_TEXT_CONNECTIONS",
    "topic_name": "Craft and Structure / Cross-Text Connections",
    "difficulty": "EASY",
    "prompt": "**Text 1**\nPublic policy researcher Anthony Fowler studied the history of elections in Australia, a country that requires citizens to vote. Fowler argues that requiring citizens to vote leads to a significant increase in voters who would otherwise not have the time or motivation to vote. Thus, election results in countries that require citizens to vote better reflect the preferences of the country as a whole.\n\n**Text 2**\nGovernments in democratic countries function better when more people vote. However, forcing people to vote may have negative consequences. Shane P. Singh and Jason Roy studied what happens when a country requires its citizens to vote. They found that when people feel forced to vote, they tend to spend less time looking for information about their choices when voting. As a result, votes from these voters may not reflect their actual preferences.\n\nBased on the texts, how would Singh and Roy (Text 2) most likely respond to the research discussed in Text 1?",
    "options": [
      {
        "id": "b1c01293-1633-3cac-ac68-566e6bc70a49",
        "key": "A",
        "text": "Only countries of a certain population size should implement mandatory voting."
      },
      {
        "id": "9688b722-64ec-3587-a5bb-beae9877e49e",
        "key": "B",
        "text": "People who are forced to vote are likely to become politically engaged in other ways, such as volunteering or running for office."
      },
      {
        "id": "1fd89991-2235-3419-afdf-a8fbf3c697e9",
        "key": "C",
        "text": "Requiring people to vote does not necessarily lead to election outcomes that better represent the preferences of the country as a whole."
      },
      {
        "id": "9c65650d-86ec-3d95-bd8f-1d9e079fa0f1",
        "key": "D",
        "text": "Countries that require voting must also make the process of voting easier for their citizens."
      }
    ],
    "correct_option_id": "1fd89991-2235-3419-afdf-a8fbf3c697e9",
    "explanation": "Choice C is the best answer. Text 1 claims that mandatory voting results in elections that \"better reflect the preferences of the country.\" Singh and Roy disagree. They claim that more voters doesn’t equal more quality votes—instead, they argue that forced voting may lead to less-informed votes that \"may not reflect [voters’] actual preferences.\"\n\nChoice A is incorrect. Neither text mentions the population size of countries that require voting, or how that might affect election outcomes. Choice B is incorrect. Neither text discusses the effects of mandatory voting on other forms of political engagement. Choice D is incorrect. Neither text discusses the ease or difficulty of the voting process in countries that require voting.",
    "source_id": "02fd3da7",
    "source_number": 96,
    "authored_distractors": false
  },
  {
    "id": "667e5adc-50d4-573b-be6b-a19af0853503",
    "external_key": "SAT_RW:06b96bfc",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "A musician and member of the Quechua of Peru, Renata Flores Rivera was eager to promote the Quechua language in her music, but she was ______ speaking it. She met this challenge by asking her grandmother, a native speaker of Quechua, to help her pronounce words in her song lyrics and also by taking classes in the language.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "a8492f14-e043-37a2-9ca8-d9fce7306780",
        "key": "A",
        "text": "prepared for"
      },
      {
        "id": "d1daad39-c338-3fb2-b18c-7fcfaae3c75e",
        "key": "B",
        "text": "inexperienced with"
      },
      {
        "id": "dbc7bdeb-9f66-372a-9403-3f15970b922f",
        "key": "C",
        "text": "skilled in"
      },
      {
        "id": "076afb1f-0ffa-323f-953d-dfa941d6a4bc",
        "key": "D",
        "text": "excited about"
      }
    ],
    "correct_option_id": "d1daad39-c338-3fb2-b18c-7fcfaae3c75e",
    "explanation": "Choice B is the best answer because it most logically completes the text’s discussion of Renata Flores Rivera’s use of Quechua in her music. In this context, “inexperienced with” means not accustomed to. The text indicates that Flores Rivera wanted to promote the Quechua language in her music and overcame a challenge by seeking help with pronunciation from her grandmother and by taking language classes. This context conveys the idea that Flores Rivera was not sufficiently familiar with Quechua to use it in her music without help. Thus, she was inexperienced with speaking the language, which she addressed by seeking help.\n\nChoice A is incorrect because describing Flores Rivera as “prepared for”—or ready for—speaking Quechua wouldn’t make sense in context. The text indicates that speaking Quechua presented a challenge, but if she were ready to speak the language, then there would be no challenge. Choice C is incorrect because describing Flores Rivera as “skilled in”—meaning good at or capable of—speaking Quechua wouldn’t make sense in context. The text indicates that speaking Quechua presented a challenge, but if she were capable of speaking the language, then there would be no challenge. Choice D is incorrect. Flores Rivera was likely “excited about”—or thrilled or delighted with—speaking Quechua, but this wouldn’t make sense in context. The text indicates that speaking Quechua presented a challenge, but if she were delighted with speaking the language, then there would be no challenge.",
    "source_id": "06b96bfc",
    "source_number": 97,
    "authored_distractors": false
  },
  {
    "id": "22d9d5f8-139f-5acd-9823-a20d24922402",
    "external_key": "SAT_RW:0f040c50",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "The following text is from Yann Martel’s 2001 novel *Life of Pi*. The narrator’s family owned a zoo when he was a child.\n\n> It was a huge zoo, spread over numberless acres, big enough to require a train to explore it, though it seemed to get smaller as I grew older, train included.\n> \n> *©2001 by Yann Martel*\n\nAs used in the text, what does the word “spread” most nearly mean?",
    "options": [
      {
        "id": "10f3649d-14ec-34e9-ac6b-b1dbbd309852",
        "key": "A",
        "text": "Hidden"
      },
      {
        "id": "46047cb7-1d8e-3722-af36-6de22cc84306",
        "key": "B",
        "text": "Discussed"
      },
      {
        "id": "259f0419-2c23-34cb-8ae5-4bd360c7c4ec",
        "key": "C",
        "text": "Extended"
      },
      {
        "id": "7a923b7b-bbc6-3286-af00-1e80ddbf0bdc",
        "key": "D",
        "text": "Coated"
      }
    ],
    "correct_option_id": "259f0419-2c23-34cb-8ae5-4bd360c7c4ec",
    "explanation": "Choice C is the best answer because as used in the text, “spread” most nearly means extended. The text states that the zoo is “huge,” that it covers “numberless acres,” and that it is large enough that a train is needed to explore it. Thus, the text’s emphasis on the zoo’s size suggests that the zoo extended, or stretched, over a large area of land.\n\nChoice A is incorrect because if the zoo covers “numberless acres,” then it could not reasonably be described as hidden, or concealed from view. Choice B is incorrect because there is nothing in the text to suggest that the zoo was discussed, or talked about. Rather, the text focuses on the zoo’s large size. Choice D is incorrect. Although in some contexts “spread” can mean coated, it doesn’t have that meaning in this context because to coat something means to apply a thin layer of a liquid substance, such as oil or paint, to a surface. Therefore, it would not be accurate to say that the zoo coated the acres on which it sits.",
    "source_id": "0f040c50",
    "source_number": 98,
    "authored_distractors": false
  },
  {
    "id": "c141efa7-bdf1-5d46-9ace-a7f32049cc58",
    "external_key": "SAT_RW:e1d5d5df",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "According to botanists, a viburnum plant experiencing insect damage may develop erineum—a discolored, felty growth—on its leaf blades. A ______ viburnum plant, on the other hand, will have leaves with smooth surfaces and uniformly green coloration.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "9bc14984-defb-310d-aa9c-222d5e790420",
        "key": "A",
        "text": "struggling"
      },
      {
        "id": "987f980b-8941-3301-b0f6-83954852cf12",
        "key": "B",
        "text": "beneficial"
      },
      {
        "id": "b05d499f-879b-3e2f-9933-e64a4b73bc74",
        "key": "C",
        "text": "simple"
      },
      {
        "id": "2fff62b4-7338-3326-a376-7b4614532e22",
        "key": "D",
        "text": "healthy"
      }
    ],
    "correct_option_id": "2fff62b4-7338-3326-a376-7b4614532e22",
    "explanation": "Choice D is the best answer because it most logically completes the text’s discussion of damage to viburnum plants. In this context, “healthy” would mean not distressed or diseased. The text states that insect damage may cause viburnum plants to be discolored and have abnormal growths. In the next sentence, the phrase “on the other hand” indicates a contrast with the description of plants suffering from damage. Thus, the context contrasts the appearance of healthy, undamaged plants with the appearance of damaged plants.\n\nChoice A is incorrect because in this context, “struggling” would mean working against difficulties. The text first describes viburnum plants experiencing damage by insects, and the phrase “on the other hand” then establishes a contrast with that description. It wouldn’t make sense to contrast struggling viburnum plants with those being damaged by insects, because in both cases the plants would be experiencing difficulties. Choice B is incorrect because in this context, “beneficial” would mean producing good or helpful effects. The text doesn’t discuss how viburnum plants affect other things or suggest that the plants are helpful in some way; rather, it focuses on how viburnum plants are affected by certain conditions. Choice C is incorrect because in this context “simple” would mean plain or uncomplicated. The text doesn’t discuss whether certain viburnum plants are complicated or uncomplicated; rather, it focuses on how viburnum plants are affected by certain conditions.",
    "source_id": "e1d5d5df",
    "source_number": 99,
    "authored_distractors": false
  },
  {
    "id": "9ecb9b6a-9906-5e17-b19b-e501ccb8f579",
    "external_key": "SAT_RW:9e501aaf",
    "discipline_code": "SAT_RW",
    "topic_code": "CRAFT_WORDS_IN_CONTEXT",
    "topic_name": "Craft and Structure / Words in Context",
    "difficulty": "EASY",
    "prompt": "Research conducted by planetary scientist Katarina Miljkovic suggests that the Moon’s surface may not accurately ______ early impact events. When the Moon was still forming, its surface was softer, and asteroid or meteoroid impacts would have left less of an impression; thus, evidence of early impacts may no longer be present.\n\nWhich choice completes the text with the most logical and precise word or phrase?",
    "options": [
      {
        "id": "5bc4e23a-b68c-3598-88c7-9c2d7b3f692d",
        "key": "A",
        "text": "reflect"
      },
      {
        "id": "cedda364-3382-3de3-968b-ddeb117ffabc",
        "key": "B",
        "text": "receive"
      },
      {
        "id": "0ced8dfd-0690-3752-9667-060432dfe4c1",
        "key": "C",
        "text": "evaluate"
      },
      {
        "id": "16a1445e-3cef-386a-958e-b7369cdca811",
        "key": "D",
        "text": "mimic"
      }
    ],
    "correct_option_id": "5bc4e23a-b68c-3598-88c7-9c2d7b3f692d",
    "explanation": "Choice A is the best answer because it most logically completes the text’s discussion of the Moon’s surface. In this context, “reflect” means show or make apparent. The text states that because the surface of the Moon was softer when the Moon was still forming than it is now, early asteroid and meteoroid impacts “would have left less of an impression” and, as a result, evidence of them may no longer exist. This context supports the idea that the surface of the Moon may not accurately show signs of early impact events.\n\nChoice B is incorrect because it wouldn’t make sense to say that the surface of the Moon may not accurately “receive,” or acquire or experience, early impacts from asteroids or meteoroids. The text indicates that the impacts have already occurred, and it isn’t clear how the Moon’s surface could be accurate or inaccurate in experiencing them. Choice C is incorrect because it wouldn’t make sense to say that the surface of the Moon may not accurately “evaluate,” or determine the significance or condition of, early impacts from asteroids or meteoroids, since that would suggest that it’s possible for the Moon’s surface to make a decision of any kind. Choice D is incorrect. In this context, “mimic” would mean to deliberately simulate or closely imitate something. It wouldn’t make sense to say that the surface of the Moon may not accurately mimic early asteroid and meteoroid impacts, since that would suggest that it’s possible for the Moon to deliberately imitate something.",
    "source_id": "9e501aaf",
    "source_number": 100,
    "authored_distractors": false
  },
  {
    "id": "61f1c9b2-f571-55dd-a96f-bd69cefc2c94",
    "external_key": "SAT_RW:e3bbf2bf",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "EASY",
    "prompt": "While researching a topic, a student has taken the following notes:\n- In World War I, US soldiers who were members of the Choctaw Nation in Oklahoma participated in the Choctaw Code Talkers program.\n- The Choctaw Code Talkers were trained to relay coded military information in their native language.\n- In World War II, the US Army recruited Navajo (Diné) soldiers to transmit coded messages in their native language.\n- These soldiers were known as the Navajo Code Talkers.\n\nThe student wants to emphasize a similarity between the Choctaw Code Talkers and the Navajo Code Talkers. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "891d2efe-b2a8-3eee-ad99-8ff7925d0996",
        "key": "A",
        "text": "US soldiers who were members of the Choctaw Nation in Oklahoma used their native language to relay coded information."
      },
      {
        "id": "0a18cbe8-6c63-323f-afef-909e6c4ab926",
        "key": "B",
        "text": "In World War II, one group of Navajo (Diné) soldiers was known as the Navajo Code Talkers."
      },
      {
        "id": "8726fca0-abbc-327d-ae56-37858d6b86df",
        "key": "C",
        "text": "Both the Choctaw Code Talkers and the Navajo Code Talkers transmitted coded military messages in the soldiers’ native languages."
      },
      {
        "id": "0267358a-7353-37fc-a5ad-37a355f951a6",
        "key": "D",
        "text": "The Choctaw Code Talkers, not the Navajo Code Talkers, served in World War I."
      }
    ],
    "correct_option_id": "8726fca0-abbc-327d-ae56-37858d6b86df",
    "explanation": "Choice C is the best answer. The sentence emphasizes a similarity between the Choctaw Code Talkers and the Navajo Code Talkers by explaining that both groups used their native languages to transmit coded messages for the military.\n\nChoice A is incorrect. The sentence describes the Choctaw Code Talkers; it doesn’t emphasize a similarity between the Choctaw Code Talkers and the Navajo Code Talkers. Choice B is incorrect. The sentence introduces the Navajo Code Talkers; it doesn’t emphasize a similarity between the Choctaw Code Talkers and the Navajo Code Talkers. Choice D is incorrect. The sentence emphasizes a difference between the Choctaw Code Talkers and the Navajo Code Talkers; it doesn’t emphasize a similarity.",
    "source_id": "e3bbf2bf",
    "source_number": 101,
    "authored_distractors": false
  },
  {
    "id": "46edbdb0-0b49-55f9-9b54-9825c606926e",
    "external_key": "SAT_RW:00221c00",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "EASY",
    "prompt": "In 1815, while in exile in Jamaica, Venezuelan revolutionary Simón Bolívar penned a letter praising England’s republican government and expressing hope that Latin American nations seeking independence from Spain might achieve something similar. The letter was addressed to a local merchant, Henry Cullen; ______ though, Bolívar’s goal was to persuade political leaders from England and Europe to support his cause.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "879581ae-f88c-3fcf-ad96-0391d2bd5f10",
        "key": "A",
        "text": "additionally,"
      },
      {
        "id": "79778e52-23ba-3157-94bf-862b0eb2e566",
        "key": "B",
        "text": "ultimately,"
      },
      {
        "id": "2a345907-1ae3-3617-8e42-da9b8b879570",
        "key": "C",
        "text": "accordingly,"
      },
      {
        "id": "f00482cc-f138-3efb-816a-18907a77ff97",
        "key": "D",
        "text": "consequently,"
      }
    ],
    "correct_option_id": "79778e52-23ba-3157-94bf-862b0eb2e566",
    "explanation": "Choice B is the best answer. “Ultimately” means “in the long run” or “at the highest level.” Although Bolívar wrote to a local merchant, his ultimate goal was to send a message to political leaders in Europe. Therefore, “ultimately” fits perfectly in this context.\n\nChoice A is incorrect. This choice uses a transition that indicates the addition of an agreeing idea. However, the second part of the sentence actually disagrees with the first part. Bolívar addressed the letter to Cullen, but he was really sending a message to someone else. Notice how the contrast word “though” also acts as a transition between these ideas. Choice C is incorrect. This choice uses a cause-and-effect transition. Bolívar’s writing of the letter to Cullen would not cause him to have a goal of persuading European powers to support him. Choice D is incorrect. This choice uses a cause-and-effect transition. Bolívar’s writing of the letter to Cullen would not cause him to have a goal of persuading European powers to support him.",
    "source_id": "00221c00",
    "source_number": 102,
    "authored_distractors": false
  },
  {
    "id": "10724bb6-3a99-54f7-8fa1-f65c89190a7c",
    "external_key": "SAT_RW:e2693197",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "EASY",
    "prompt": "While researching a topic, a student has taken the following notes:\n- *Oracles of the Pink Universe* was a 2021 exhibition at the Denver Museum of Art in Colorado.\n- It featured eight artworks by South African artist Simphiwe Ndzube.\n- One of these works is a painting titled *Assertion of Will*.\n- *Assertion of Will* depicts three standing figures.\n- The figures wear clothing made of fabric pieces stitched to the painting’s canvas.\n\nThe student wants to describe how fabric is used in *Assertion of Will*. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "04c6831e-c97f-3622-857c-d434c89b088d",
        "key": "A",
        "text": "In *Assertion of Will*, the figures’ clothing is made of fabric pieces stitched to the painting’s canvas."
      },
      {
        "id": "7aeb4ede-d814-369e-80f1-c6e707782585",
        "key": "B",
        "text": "The exhibition *Oracles of the Pink Universe* featured artworks by artist Simphiwe Ndzube."
      },
      {
        "id": "586d3e38-b788-3975-918b-74201065d30d",
        "key": "C",
        "text": "Depicting three standing, clothed figures, *Assertion of Will* is a painting by Simphiwe Ndzube."
      },
      {
        "id": "67fe6728-aa4e-3eb1-ab5b-5bc3ea555cb9",
        "key": "D",
        "text": "Simphiwe Ndzube’s *Assertion of Will* was one of eight artworks exhibited in *Oracles of the Pink Universe* at the Denver Museum of Art."
      }
    ],
    "correct_option_id": "04c6831e-c97f-3622-857c-d434c89b088d",
    "explanation": "Choice A is the best answer. This choice directly describes how fabric is used in *Assertion of Will*, by explaining that the fabric pieces are part of the painting itself.\n\nChoice B is incorrect. This choice provides contextual information about the exhibition, but it doesn’t mention anything about the painting or the fabric. Choice C is incorrect. This choice mentions that the figures are clothed, but it doesn’t explain how the fabric is integrated into the painting. Choice D is incorrect. This choice provides contextual information about the painting, but it doesn’t mention anything about the fabric or how it is used.",
    "source_id": "e2693197",
    "source_number": 103,
    "authored_distractors": false
  },
  {
    "id": "04c9d5e6-6ea8-5dc4-9ed4-048cb36e9cc0",
    "external_key": "SAT_RW:54227b8e",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "EASY",
    "prompt": "While researching a topic, a student has taken the following notes:\n- The mountain pygmy possum is a mammal species.\n- Up until 1966, it was believed to be extinct.\n- That year, a live mountain pygmy possum was identified in the wild in Australia.\n- The mountain pygmy possum is considered a Lazarus species.\n- “Lazarus species” is a term for living species of organisms that were once believed to be extinct.\n\nThe student wants to define the term “Lazarus species” and provide an example of one. Which choice most effectively uses relevant information from the notes to accomplish these goals?",
    "options": [
      {
        "id": "3684e16f-91e7-358a-9f4b-dede78c066ef",
        "key": "A",
        "text": "The term “Lazarus species” describes a living species of organism, such as the mountain pygmy possum, that was once believed to be extinct."
      },
      {
        "id": "1b48e540-081d-3815-8a05-9e88c06e7f7a",
        "key": "B",
        "text": "One example of a Lazarus species is the mountain pygmy possum, a mammal species that was identified in the wild in Australia in 1966."
      },
      {
        "id": "179ba0b9-f361-3d5d-a230-d5b8a9c5cf96",
        "key": "C",
        "text": "The mountain pygmy possum, a species of mammal, was identified in the wild in 1966."
      },
      {
        "id": "066e5289-d259-3a5d-8ffe-ff0e8d62a877",
        "key": "D",
        "text": "Sometimes, a species once believed to be extinct is later found living in the wild."
      }
    ],
    "correct_option_id": "3684e16f-91e7-358a-9f4b-dede78c066ef",
    "explanation": "Choice A is the best answer. The sentence defines the term \"Lazarus species\" and provides an example of one, explaining that a Lazarus species is a living organism that was once believed to be extinct and providing the mountain pygmy possum as an example.\n\nChoice B is incorrect. While the sentence provides an example of a Lazarus species, it doesn’t define the term \"Lazarus species.\" Choice C is incorrect. The sentence provides information about the mountain pygmy possum; it doesn’t define the term \"Lazarus species\" or explicitly identify the mountain pygmy possum as a Lazarus species. Choice D is incorrect. While the sentence describes the concept of a Lazarus species, it doesn’t define the term or provide an example of a Lazarus species.",
    "source_id": "54227b8e",
    "source_number": 104,
    "authored_distractors": false
  },
  {
    "id": "ab08bb80-0b87-56f1-a389-598a0b7e526e",
    "external_key": "SAT_RW:c78620ba",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "EASY",
    "prompt": "In 1968, US Congressman John Conyers introduced a bill to establish a national holiday in honor of Dr. Martin Luther King Jr. The bill didn’t make it to a vote, but Conyers was determined. He teamed up with Shirley Chisholm, the first Black woman to be elected to Congress, and they resubmitted the bill every session for the next fifteen years. ______ in 1983, the bill passed.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "0390365c-6106-382e-bea3-cf4fe4d93222",
        "key": "A",
        "text": "Instead,"
      },
      {
        "id": "50dd8aec-8f0c-39e9-9711-243fa722b133",
        "key": "B",
        "text": "Likewise,"
      },
      {
        "id": "74364178-9650-375f-bf2c-45c3fddcc51c",
        "key": "C",
        "text": "Finally,"
      },
      {
        "id": "b7b99a86-3021-3ff5-816f-83c10dfe428d",
        "key": "D",
        "text": "Additionally,"
      }
    ],
    "correct_option_id": "74364178-9650-375f-bf2c-45c3fddcc51c",
    "explanation": "Choice C is the best answer. “Finally” logically signals that the bill passing—following many attempts between 1968 and 1983—is the final, concluding event in the sequence described in the previous sentences.\n\nChoice A is incorrect because “instead” illogically signals that the bill passing is an alternative to one of the events described in the previous sentences. Instead, it is the final event in the sequence. Choice B is incorrect because “likewise” illogically signals that the bill passing is similar to one of the events described in the previous sentences. Instead, it is the final event in the sequence. Choice D is incorrect because “additionally” illogically signals that the bill passing is merely another event described along with the events of the previous sentences. Instead, it is the final, concluding event in the sequence.",
    "source_id": "c78620ba",
    "source_number": 105,
    "authored_distractors": false
  },
  {
    "id": "73ca41c1-499b-54e9-aea2-479bfe08c20c",
    "external_key": "SAT_RW:20733eac",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "EASY",
    "prompt": "It has long been thought that humans first crossed a land bridge into the Americas approximately 13,000 years ago. ______ based on radiocarbon dating of samples uncovered in Mexico, a research team recently suggested that humans may have arrived more than 30,000 years ago—much earlier than previously thought.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "68c7756b-d649-370a-b976-720a583b48c2",
        "key": "A",
        "text": "As a result,"
      },
      {
        "id": "9518c2ec-34de-38e9-b7e3-363f0eced53e",
        "key": "B",
        "text": "Similarly,"
      },
      {
        "id": "ade8ac9f-8c5c-32e4-b6dc-de063cea65d6",
        "key": "C",
        "text": "However,"
      },
      {
        "id": "68f969e8-0eda-3f06-bb36-a9ce810f8391",
        "key": "D",
        "text": "In conclusion,"
      }
    ],
    "correct_option_id": "ade8ac9f-8c5c-32e4-b6dc-de063cea65d6",
    "explanation": "Choice C is the best answer. “However” logically signals that the theory discussed in this sentence—that humans may have arrived in the Americas over 30,000 years ago—contrasts with the previously discussed theory that humans arrived around 13,000 years ago.\n\nChoice A is incorrect because “as a result” illogically signals that the theory in this sentence is the result of the theory discussed in the previous sentence. Instead, this theory contrasts with the previous one. Choice B is incorrect because “similarly” illogically signals that the theory in this sentence is similar to the theory discussed in the previous sentence. Instead, this theory contrasts with the previous one. Choice D is incorrect because “in conclusion” illogically signals that the theory in this sentence concludes or summarizes the discussion of the previous theory. Instead, this theory contrasts with the previous one.",
    "source_id": "20733eac",
    "source_number": 106,
    "authored_distractors": false
  },
  {
    "id": "004d63ed-fee5-5476-b46e-348236a0669a",
    "external_key": "SAT_RW:e1079609",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "EASY",
    "prompt": "In 1845, the United States District Court for the state of Iowa was established. Initially, the court’s jurisdiction was a single district that encompassed the entire state, but as Iowa’s population grew, this single district began to struggle to serve the needs of everyone in the state. ______ the court’s jurisdiction was subdivided into two districts, each with its own district court.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "bdb56208-cc7e-398c-9c6c-9009ae4c9eaf",
        "key": "A",
        "text": "Nevertheless,"
      },
      {
        "id": "8b734212-87ee-3bf7-b08e-f170bc27a143",
        "key": "B",
        "text": "Ultimately,"
      },
      {
        "id": "9c3f50ec-9992-3ebb-8f66-6b1363c7c345",
        "key": "C",
        "text": "Additionally,"
      },
      {
        "id": "6da46dcc-fe4e-3962-90ef-3a668bdbb16c",
        "key": "D",
        "text": "For example,"
      }
    ],
    "correct_option_id": "8b734212-87ee-3bf7-b08e-f170bc27a143",
    "explanation": "Choice B is the best answer. “Ultimately” logically signals that the information in this sentence—that the court’s jurisdiction was subdivided into two districts—was the eventual outcome or resolution of the previously described struggle of the single district to serve the needs of everyone in the state.\n\nChoice A is incorrect because “nevertheless” illogically signals that the information in the sentence is true despite the single district’s struggle to serve the state’s needs. Instead, the sentence describes the eventual resolution of that struggle. Choice C is incorrect because “additionally” illogically signals that the information in the sentence is merely an additional fact related to the single district’s struggle. Instead, the sentence describes the eventual resolution of that struggle. Choice D is incorrect because “for example” illogically signals that the information in the sentence provides a specific example of the single district’s struggle to serve the state’s needs. Instead, the sentence describes the eventual resolution of that struggle.",
    "source_id": "e1079609",
    "source_number": 107,
    "authored_distractors": false
  },
  {
    "id": "7cb1a0e0-08a7-5904-ab52-36d77a5c55f9",
    "external_key": "SAT_RW:ca4ff52d",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_RHETORICAL_SYNTHESIS",
    "topic_name": "Expression of Ideas / Rhetorical Synthesis",
    "difficulty": "EASY",
    "prompt": "While researching a topic, a student has taken the following notes:\n- Muslins are woven cotton fabrics with a variety of uses.\n- Dhaka muslin is a handmade fabric produced in Dhaka, Bangladesh.\n- It has an extremely fine weave and is primarily used to make luxury clothing.\n- Sheeting muslin is a machine-made fabric produced in factories.\n- It has a coarse weave and is primarily used to upholster furniture and create backdrops for theater sets.\n\nThe student wants to emphasize a difference between the two muslins. Which choice most effectively uses relevant information from the notes to accomplish this goal?",
    "options": [
      {
        "id": "b745733e-5351-3210-8c1f-575b094234bb",
        "key": "A",
        "text": "Dhaka muslin is a handmade fabric with an extremely fine weave, while sheeting muslin is machine made with a coarse weave."
      },
      {
        "id": "32a6ce33-94f1-3ea5-b9a6-cc9c8edf0179",
        "key": "B",
        "text": "Dhaka muslin and sheeting muslin are two different types of woven cotton fabrics."
      },
      {
        "id": "bab491bd-2195-340e-8dfb-3d141766ca75",
        "key": "C",
        "text": "Muslins can be used in a variety of ways, from making luxury clothing to upholstering furniture and creating backdrops for theater sets."
      },
      {
        "id": "57dc1c63-c908-31dd-8a49-cfe67ada07ca",
        "key": "D",
        "text": "Sheeting muslin is machine made, has a coarse weave, and is used for furniture and theater sets."
      }
    ],
    "correct_option_id": "b745733e-5351-3210-8c1f-575b094234bb",
    "explanation": "Choice A is the best answer. The difference between the two different kinds of muslin is emphasized.\n\nChoice B is incorrect. This choice lists two kinds of muslins, but does not say how they are different from one another. Choice C is incorrect. This choice does not emphasize a difference between the two muslins. Choice D is incorrect. This choice does not emphasize a difference between the two muslins. It only describes sheeting muslin.",
    "source_id": "ca4ff52d",
    "source_number": 108,
    "authored_distractors": false
  },
  {
    "id": "ad5e55c3-126e-5757-bd51-d002faf68efc",
    "external_key": "SAT_RW:92fe0ed7",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "EASY",
    "prompt": "Geoscientists have long considered Hawaii’s Mauna Loa volcano to be Earth’s largest shield volcano by volume, measuring approximately 74,000 cubic kilometers. ______ according to a 2020 study by local geoscientist Michael Garcia, Hawaii’s Pūhāhonu shield volcano is significantly larger, boasting a volume of about 148,000 cubic kilometers.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "84a6b21c-aa5c-3403-b191-5be4c440b6e8",
        "key": "A",
        "text": "Secondly,"
      },
      {
        "id": "6436a801-6d62-3f91-b725-d85708e851c5",
        "key": "B",
        "text": "Consequently,"
      },
      {
        "id": "0c37ff08-291e-3cf0-9845-f4713da68b10",
        "key": "C",
        "text": "Moreover,"
      },
      {
        "id": "1039ec93-9200-3612-a01f-e7471cc0e8f3",
        "key": "D",
        "text": "However,"
      }
    ],
    "correct_option_id": "1039ec93-9200-3612-a01f-e7471cc0e8f3",
    "explanation": "Choice D is the best answer. “However” logically signals that this sentence, which indicates that the Pūhāhonu volcano may be larger than the Mauna Loa volcano, offers a contrast to or refutation of the previous assumption that Mauna Loa is the largest shield volcano.\n\nChoice A is incorrect because “secondly” illogically signals that this sentence merely offers an additional or secondary point concerning the previous assumption that Mauna Loa is the largest shield volcano. Instead, the sentence offers a contrast to or refutation of that assumption. Choice B is incorrect because “consequently” illogically signals that this sentence offers a result or consequence of the previous assumption that Mauna Loa is the largest shield volcano. Instead, the sentence offers a contrast to or refutation of that assumption. Choice C is incorrect because “moreover” illogically signals that this sentence merely adds to the previous assumption that Mauna Loa is the largest shield volcano. Instead, the sentence offers a contrast to or refutation of that assumption.",
    "source_id": "92fe0ed7",
    "source_number": 109,
    "authored_distractors": false
  },
  {
    "id": "589b88de-20a4-547f-96fc-4bdcb6724b14",
    "external_key": "SAT_RW:97e2e364",
    "discipline_code": "SAT_RW",
    "topic_code": "EXPRESSION_TRANSITIONS",
    "topic_name": "Expression of Ideas / Transitions",
    "difficulty": "EASY",
    "prompt": "Okot p’Bitek’s poem *Song of Lawino* (1966) explores postcolonial Ugandan life through the eyes of a woman living in a rural village. With its vibrant imagery, bitingly satiric tone, and dexterous use of traditional Acholi song and phraseology, the poem inspired a generation of East African writers. ______ those who adopted its style are often referred to as Okot School poets.\n\nWhich choice completes the text with the most logical transition?",
    "options": [
      {
        "id": "e31a7968-3da7-32ed-86f2-8d1a868f303c",
        "key": "A",
        "text": "Nevertheless,"
      },
      {
        "id": "32a51e51-40a4-3f88-a6ca-3db17f85320f",
        "key": "B",
        "text": "Fittingly,"
      },
      {
        "id": "c159c2bc-3517-366f-8d63-1fdf9cbc3b2c",
        "key": "C",
        "text": "By comparison,"
      },
      {
        "id": "2f215583-6fc4-3a0b-b809-4d7c1251364e",
        "key": "D",
        "text": "Instead,"
      }
    ],
    "correct_option_id": "32a51e51-40a4-3f88-a6ca-3db17f85320f",
    "explanation": "Choice B is the best answer. “Fittingly” is a transition that means “appropriately” or “suitably,” and it is appropriate that writers who adopted their style from Okot p’Bitek would be known as the Okot School poets.\n\nChoice A is incorrect. This choice uses a disagreement transition. But this sentence is not disagreeing with anything—rather, it’s discussing how it makes sense for those writers who adopted Okot’s style to be known as the Okot School poets. Choice C is incorrect. This choice uses a transition that compares two ideas. But this sentence is not comparing the Okot School poets and their style to Okot’s style. Choice D is incorrect. This choice uses a disagreement transition. But this sentence is not disagreeing with anything—rather, it’s discussing how it makes sense for those writers who adopted Okot’s style to be known as the Okot School poets.",
    "source_id": "97e2e364",
    "source_number": 110,
    "authored_distractors": false
  },
  {
    "id": "4de73053-a468-536d-b395-b1d73d2271cb",
    "external_key": "SAT_RW:c5d39bc7",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "EASY",
    "prompt": "Scientists believe that, unlike most other species of barnacle, turtle barnacles (*Chelonibia testudinari*) can dissolve the cement-like secretions they use to attach ______ to a sea turtle shell, enabling the barnacles to move short distances across the shell’s surface.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "8690ac7d-2875-331a-92ca-65090930e862",
        "key": "A",
        "text": "it"
      },
      {
        "id": "e69f7dcb-1c63-3222-956c-ebcc2a244984",
        "key": "B",
        "text": "themselves"
      },
      {
        "id": "8927b94f-46db-390e-97d9-ef265bdd5aab",
        "key": "C",
        "text": "them"
      },
      {
        "id": "2adc4e21-a96b-3633-a6de-95e1d24fb395",
        "key": "D",
        "text": "itself"
      }
    ],
    "correct_option_id": "e69f7dcb-1c63-3222-956c-ebcc2a244984",
    "explanation": "Choice B is the best answer. The convention being tested is pronoun-antecedent agreement. The plural reflexive pronoun “themselves” agrees in number with the plural antecedent “turtle barnacles,” correctly indicating what is attached to a sea turtle shell.\n\nChoice A is incorrect because the singular pronoun “it” doesn’t agree in number with the plural antecedent “turtle barnacles.” Choice C is incorrect because it results in an unclear and confusing sentence. In this context, it’s unclear what the plural pronoun “them” refers to. Choice D is incorrect because the singular reflexive pronoun “itself” doesn’t agree in number with the plural antecedent “turtle barnacles.”",
    "source_id": "c5d39bc7",
    "source_number": 111,
    "authored_distractors": false
  },
  {
    "id": "08dc4418-36a9-55bf-b817-b970b35fcedf",
    "external_key": "SAT_RW:e2759b92",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "EASY",
    "prompt": "Occupying a significant part of modern-day Nigeria, the Kingdom of Benin was one of the major powers in West Africa between the thirteenth and nineteenth centuries. It ______ ruled by Oba Ewuare I from 1440 to 1473.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "13ce250a-79e3-3b3a-b1fc-8990f209cebf",
        "key": "A",
        "text": "is"
      },
      {
        "id": "b392cb27-fa07-34f8-a760-e39f362f5d65",
        "key": "B",
        "text": "will be"
      },
      {
        "id": "dcb08e9a-a482-3952-b57a-3ee16552934e",
        "key": "C",
        "text": "has been"
      },
      {
        "id": "fab646da-4a6d-3808-bdd1-64c99a1caaa8",
        "key": "D",
        "text": "was"
      }
    ],
    "correct_option_id": "fab646da-4a6d-3808-bdd1-64c99a1caaa8",
    "explanation": "Choice D is the best answer. The convention being tested is the use of verbs to express tense in a sentence. In this choice, the past tense verb “was ruled” correctly indicates that Oba Ewuare I ruled the Kingdom of Benin in the distant past (from 1440 to 1473). This past tense verb choice is consistent with the other past tense verb (“was”) used to describe the Kingdom of Benin.\n\nChoice A is incorrect because the present tense verb “is ruled” doesn’t indicate that Oba Ewuare I ruled the Kingdom of Benin in the distant past. Choice B is incorrect because the future tense verb “will be ruled” doesn’t indicate that Oba Ewuare I ruled the Kingdom of Benin in the distant past. Choice C is incorrect because the present perfect tense verb “has been ruled” doesn’t indicate that Oba Ewuare I ruled the Kingdom of Benin in the distant past.",
    "source_id": "e2759b92",
    "source_number": 112,
    "authored_distractors": false
  },
  {
    "id": "bbeb65cc-9369-563e-959c-52812e30180a",
    "external_key": "SAT_RW:72b3db98",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "EASY",
    "prompt": "Mia Heavener’s 2019 novel *Under Nushagak Bluff*, which takes place in a mid-twentieth-century rural Alaskan fishing ______ the story of three Yup’ik women who grapple with the rise of commercial fisheries and other changes affecting their community.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "a913c534-b39d-3d36-a916-af129d88a9bb",
        "key": "A",
        "text": "village. Tells"
      },
      {
        "id": "2eb175e2-fee3-3b88-89c2-8e1b7bd37456",
        "key": "B",
        "text": "village tells"
      },
      {
        "id": "1185a320-c419-34bc-90b7-faf790ba1649",
        "key": "C",
        "text": "village: tells"
      },
      {
        "id": "c82e40a0-dd52-362b-bee6-969f875251b6",
        "key": "D",
        "text": "village, tells"
      }
    ],
    "correct_option_id": "c82e40a0-dd52-362b-bee6-969f875251b6",
    "explanation": "Choice D is the best answer. The convention being tested is the use of punctuation within a sentence. The comma after “village” pairs with the comma after “Under Nushagak Bluff” to separate the supplementary relative clause (“which...village”) from the rest of the sentence. This supplementary relative clause functions to provide additional information about the setting of Heavener’s novel, and the pair of commas indicates that this element could be removed without affecting the grammatical coherence of the sentence.\n\nChoice A is incorrect because it results in two rhetorically unacceptable sentence fragments, one beginning with “Mia” and the other beginning with “tells.” Choice B is incorrect because it fails to use appropriate punctuation to separate the supplementary relative clause (“which...village”) from the rest of the sentence. Choice C is incorrect because a colon can’t be paired with a comma in this way to separate the supplementary relative clause (“which...village”) from the rest of the sentence. A colon can be used between two main clauses or a main clause and supplement, but here there is no main clause on either side of the colon.",
    "source_id": "72b3db98",
    "source_number": 113,
    "authored_distractors": false
  },
  {
    "id": "2702a51e-43b7-51c9-a359-be862419ed31",
    "external_key": "SAT_RW:5ad2a12c",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "EASY",
    "prompt": "The First Folio, published in 1623, is the first collection of William Shakespeare’s plays. The collection ______ 18 plays that might otherwise have been lost, such as *Julius Caesar* and *Macbeth*.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "7d1a66b7-5c6d-3dda-9fd4-f0cc60dde0f3",
        "key": "A",
        "text": "to be including"
      },
      {
        "id": "211cdb4c-0f03-3fec-811a-70d0d48514d0",
        "key": "B",
        "text": "including"
      },
      {
        "id": "a89cdd12-c532-3b40-88f7-9e2185c290fc",
        "key": "C",
        "text": "to include"
      },
      {
        "id": "9f00ef29-063c-38d3-ba8c-e96d3b9d618d",
        "key": "D",
        "text": "includes"
      }
    ],
    "correct_option_id": "9f00ef29-063c-38d3-ba8c-e96d3b9d618d",
    "explanation": "Choice D is the best answer. The convention being tested is the use of verb forms within a sentence. A main clause requires a finite (tensed) verb to perform the action of the subject (in this case, \"the collection\"), and this choice supplies the finite present tense verb \"includes\" to indicate what is in the collection.\n\nChoice A is incorrect because it results in an ungrammatical sentence. The nonfinite to-infinitive \"to be including\" doesn’t supply the main clause with a finite verb. Choice B is incorrect because it results in an ungrammatical sentence. The nonfinite participle \"including\" doesn’t supply the main clause with a finite verb. Choice C is incorrect because it results in an ungrammatical sentence. The nonfinite to-infinitive \"to include\" doesn’t supply the main clause with a finite verb.",
    "source_id": "5ad2a12c",
    "source_number": 114,
    "authored_distractors": false
  },
  {
    "id": "877a806a-d353-50e1-87c7-560711074407",
    "external_key": "SAT_RW:02871a0d",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "EASY",
    "prompt": "In her large-scale sculpture *Casa-Isla*, artist Edra Soto included references to her childhood in Puerto Rico. For example, the sculpture’s steel panels have a crisscrossing pattern inspired by the iron gates ______\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "743aa309-8eca-3abb-ac13-fc43d831b37b",
        "key": "A",
        "text": "Soto would see in her neighborhood?"
      },
      {
        "id": "23469afd-2aac-369a-8dcc-00deb223cfea",
        "key": "B",
        "text": "Soto would see in her neighborhood."
      },
      {
        "id": "b7207a3e-224b-3867-95ef-de05f5646b47",
        "key": "C",
        "text": "would Soto see in her neighborhood."
      },
      {
        "id": "303edb57-839e-308c-8043-80fe5a448b74",
        "key": "D",
        "text": "would Soto see in her neighborhood?"
      }
    ],
    "correct_option_id": "23469afd-2aac-369a-8dcc-00deb223cfea",
    "explanation": "Choice B is the best answer. The convention being tested is end-of-sentence punctuation. This choice correctly uses a period to punctuate a declarative sentence (\"For example...neighborhood\").\n\nChoice A is incorrect. It’s unconventional to use a question mark in this way to punctuate a declarative sentence. Choice C is incorrect. The structure requires a declarative clause at the end of the sentence that states where Soto saw the steel panels, not an incomplete interrogative clause that asks a direct question, such as \"would Soto see in her neighborhood.\" Choice D is incorrect. The structure requires a period and a declarative clause at the end of the sentence that states where Soto saw the steel panels, not an incomplete interrogative clause asking a direct question, such as \"would Soto see in her neighborhood?\"",
    "source_id": "02871a0d",
    "source_number": 115,
    "authored_distractors": false
  },
  {
    "id": "7b00f4e4-9dbe-5681-a66f-1db09620b41d",
    "external_key": "SAT_RW:1448f43f",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "EASY",
    "prompt": "Unsupervised machine learning is an approach that computer scientists like Nina Miolane use to engineer artificial intelligence technologies. It involves training computer algorithms to organize unlabeled data sets. Multitask learning is another approach. ______ involves training computer models to perform multiple tasks at the same time.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "52ab5261-3e04-3a10-924b-a3e40c23bf7c",
        "key": "A",
        "text": "Those"
      },
      {
        "id": "a905e43a-ba54-3dd2-acf2-3d1e41e978ef",
        "key": "B",
        "text": "They"
      },
      {
        "id": "74a747bd-f3ba-354e-be72-95e102805f5a",
        "key": "C",
        "text": "It"
      },
      {
        "id": "5dda6ff3-21dd-3256-b067-959b6c5216d9",
        "key": "D",
        "text": "Some"
      }
    ],
    "correct_option_id": "74a747bd-f3ba-354e-be72-95e102805f5a",
    "explanation": "Choice C is the best answer. The convention being tested is pronoun-antecedent agreement. The singular pronoun \"it\" agrees in number with the singular antecedent \"multitask learning\" and clearly indicates what multitask learning involves.\n\nChoice A is incorrect because the plural demonstrative pronoun \"those\" doesn’t agree in number with the singular antecedent \"multitask learning.\" Choice B is incorrect because the plural pronoun \"they\" doesn’t agree in number with the singular antecedent \"multitask learning.\" Choice D is incorrect because the indefinite pronoun \"some\" is ambiguous in this context; the resulting sentence leaves unclear what exactly \"involves training computer models.\"",
    "source_id": "1448f43f",
    "source_number": 116,
    "authored_distractors": false
  },
  {
    "id": "28249f0d-051a-5352-87c8-d16ffd082bd4",
    "external_key": "SAT_RW:175df826",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "EASY",
    "prompt": "In the 2011 documentary *The Barber of Birmingham*, civil rights activist James Armstrong recounts how his barbershop in Birmingham, Alabama, ______ as a political hub for members of the Black community during the 1950s.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "8b25dfef-ef66-3c11-9b31-20ecf80b2bfb",
        "key": "A",
        "text": "serving"
      },
      {
        "id": "b38a4e67-d5f1-3e69-b6be-ff715f84af13",
        "key": "B",
        "text": "having served"
      },
      {
        "id": "b84566b3-173e-3c13-98d1-8ff70d49ab52",
        "key": "C",
        "text": "served"
      },
      {
        "id": "7addf112-f8ff-3ad6-8c01-12831f9b1eec",
        "key": "D",
        "text": "to serve"
      }
    ],
    "correct_option_id": "b84566b3-173e-3c13-98d1-8ff70d49ab52",
    "explanation": "Choice C is the best answer. The convention being tested is the use of verb forms within a sentence. Relative clauses, such as the one beginning with \"how,\" require a finite (tensed) verb, a verb that can function as the main verb of a clause. This choice correctly supplies the clause with the finite past tense verb \"served.\"\n\nChoice A is incorrect because it results in an ungrammatical sentence. The nonfinite participle \"serving\" doesn’t supply the clause with a finite verb. Choice B is incorrect because it results in an ungrammatical sentence. The nonfinite participle \"having served\" doesn’t supply the clause with a finite verb. Choice D is incorrect because it results in an ungrammatical sentence. The nonfinite to-infinitive \"to serve\" doesn’t supply the clause with a finite verb.",
    "source_id": "175df826",
    "source_number": 117,
    "authored_distractors": false
  },
  {
    "id": "cef6d838-9504-5718-a8c4-19f75d10156d",
    "external_key": "SAT_RW:bce9910f",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_FORM_STRUCTURE_SENSE",
    "topic_name": "Standard English Conventions / Form, Structure, and Sense",
    "difficulty": "EASY",
    "prompt": "*Light of Truth* is a bronze and marble sculpture by artist Richard Hunt. It honors civil rights icon Ida B. Wells. The sculpture ______ in a tree-lined plaza in Chicago, just a few blocks from where Wells lived.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "aed99ecf-b835-3ab4-9385-b857d70236a8",
        "key": "A",
        "text": "are standing"
      },
      {
        "id": "1b344666-283b-3e19-ab8d-5bda02dd2260",
        "key": "B",
        "text": "have been standing"
      },
      {
        "id": "2f681c5a-20ac-3e9c-871b-2e8f93ff4d3e",
        "key": "C",
        "text": "stands"
      },
      {
        "id": "4e829e03-6142-3561-b48e-3e8161545d3e",
        "key": "D",
        "text": "were standing"
      }
    ],
    "correct_option_id": "2f681c5a-20ac-3e9c-871b-2e8f93ff4d3e",
    "explanation": "Choice C is the best answer. The convention being tested is subject-verb agreement. The singular verb \"stands\" agrees in number with the singular subject \"sculpture.\"\n\nChoice A is incorrect because the plural verb \"are standing\" doesn’t agree in number with the singular subject \"sculpture.\" Choice B is incorrect because the plural verb \"have been standing\" doesn’t agree in number with the singular subject \"sculpture.\" Choice D is incorrect because the plural verb \"were standing\" doesn’t agree in number with the singular subject \"sculpture.\"",
    "source_id": "bce9910f",
    "source_number": 118,
    "authored_distractors": false
  },
  {
    "id": "4e3d7108-87c8-5501-a48c-5d6b25ef09d4",
    "external_key": "SAT_RW:c88d6301",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "EASY",
    "prompt": "In the 1980s, Latino filmmakers Luis Valdez, Gregory Nava, and Ramón Menéndez helped expand on-screen representation of Latino Americans with the films *Zoot Suit* ______ and *Stand and Deliver* (1988), respectively.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "8bc38bfd-392c-3af6-997a-a5ca9b996062",
        "key": "A",
        "text": "(1981) *El Norte* (1983),"
      },
      {
        "id": "e8a27bad-7863-3d31-bb01-b7d1a21df9ba",
        "key": "B",
        "text": "(1981)—*El Norte* (1983)—"
      },
      {
        "id": "5c094927-d687-3f77-9d1c-e11325646c79",
        "key": "C",
        "text": "(1981), *El Norte* (1983),"
      },
      {
        "id": "561fe16d-d13d-396f-b190-856381a55e6a",
        "key": "D",
        "text": "(1981) *El Norte* (1983)"
      }
    ],
    "correct_option_id": "5c094927-d687-3f77-9d1c-e11325646c79",
    "explanation": "Choice C is the best answer. The convention being tested is the punctuation of items in a series. The comma after “(1981)” is used conventionally to separate the first and second items in the series, and the comma after “(1983)” is used conventionally to separate the second and third items in the series.\n\nChoice A is incorrect because it fails to use appropriate punctuation to separate the first and second items in the series. Choice B is incorrect because dashes can’t be used in this way to separate items in a simple series. Choice D is incorrect because it fails to use appropriate punctuation to separate the items in the series.",
    "source_id": "c88d6301",
    "source_number": 119,
    "authored_distractors": false
  },
  {
    "id": "3eee17cd-21ec-5705-8acd-08ba1f773e98",
    "external_key": "SAT_RW:e15c50b2",
    "discipline_code": "SAT_RW",
    "topic_code": "CONVENTIONS_BOUNDARIES",
    "topic_name": "Standard English Conventions / Boundaries",
    "difficulty": "EASY",
    "prompt": "A standard Argo float, a type of autonomous robot, measures temperature and salinity in the upper regions of ice-free oceans. More advanced floats can measure a wider range of ______ and monitor seasonal ice zones.\n\nWhich choice completes the text so that it conforms to the conventions of Standard English?",
    "options": [
      {
        "id": "ec4575a1-892e-3423-a035-ce74982cb582",
        "key": "A",
        "text": "variables: travel to greater depths"
      },
      {
        "id": "b0c0308c-4e38-342d-b04a-98c3a76b8d0f",
        "key": "B",
        "text": "variables, travel to greater depths,"
      },
      {
        "id": "61b7ca0d-65dc-35cb-be2a-b41a3a898274",
        "key": "C",
        "text": "variables travel to greater depths,"
      },
      {
        "id": "efa79147-22da-344d-bf8b-059fcd04f890",
        "key": "D",
        "text": "variables, travel to greater depths;"
      }
    ],
    "correct_option_id": "b0c0308c-4e38-342d-b04a-98c3a76b8d0f",
    "explanation": "Choice B is the best answer. The convention being tested is the punctuation of items in a series. The comma after “variables” is used conventionally to separate the first and second items in the series, and the comma after “depths” is used conventionally to separate the second and third items.\n\nChoice A is incorrect because a colon can’t be used in this way to separate items in a simple series. Choice C is incorrect because a comma is needed after “variables” to separate the first and second items in the series. Choice D is incorrect because a semicolon can’t be used in this way to separate items in a simple series.",
    "source_id": "e15c50b2",
    "source_number": 120,
    "authored_distractors": false
  }
]
$sat_question_bank$::jsonb) AS q(
    id uuid, external_key text, discipline_code text, topic_code text, topic_name text,
    difficulty text, prompt text, options jsonb, correct_option_id uuid, explanation text,
    source_id text, source_number integer, authored_distractors boolean
);

-- Abort atomically on a collision instead of changing an existing question/revision.
DO $$ BEGIN
    IF (SELECT count(*) FROM sat_question_seed) <> 240
       OR (SELECT count(DISTINCT external_key) FROM sat_question_seed) <> 240 THEN
        RAISE EXCEPTION 'SAT seed must contain 240 distinct questions';
    END IF;
    IF EXISTS (
        SELECT 1 FROM questions q JOIN sat_question_seed s ON q.external_key=s.external_key
        WHERE NOT q.deleted AND (
            q.content_version<>1 OR q.discipline_code<>s.discipline_code OR q.topic_code<>s.topic_code
            OR q.topic_name<>s.topic_name OR q.difficulty<>s.difficulty OR q.prompt<>s.prompt
            OR q.options<>s.options OR q.correct_option_id<>s.correct_option_id OR q.explanation<>s.explanation
        )
    ) THEN
        RAISE EXCEPTION 'SAT seed conflicts with existing content; no questions were replaced';
    END IF;
    IF EXISTS (
        SELECT 1 FROM disciplines d CROSS JOIN LATERAL jsonb_array_elements(d.topics) t
        JOIN sat_question_seed s ON s.discipline_code=d.code AND s.topic_code=t->>'topicCode'
        WHERE t->>'topicName' IS DISTINCT FROM s.topic_name
    ) THEN
        RAISE EXCEPTION 'SAT seed conflicts with existing topic metadata; no topics were replaced';
    END IF;
END $$;

INSERT INTO questions (
    id,created_at,updated_at,deleted,external_key,content_version,discipline_code,
    topic_code,topic_name,difficulty,prompt,options,correct_option_id,explanation,active
)
SELECT s.id,timezone('UTC',now()),timezone('UTC',now()),false,s.external_key,1,s.discipline_code,
       s.topic_code,s.topic_name,s.difficulty,s.prompt,s.options,s.correct_option_id,s.explanation,true
FROM sat_question_seed s
WHERE NOT EXISTS (SELECT 1 FROM questions q WHERE q.external_key=s.external_key AND NOT q.deleted);

-- Preserve pre-existing topics, names and gameplay configuration.
UPDATE disciplines d SET topics=(
    SELECT jsonb_agg(t.topic ORDER BY t.topic->>'topicCode')
    FROM (
        SELECT topic FROM jsonb_array_elements(d.topics) topic
        UNION
        SELECT DISTINCT jsonb_build_object('topicCode',s.topic_code,'topicName',s.topic_name)
        FROM sat_question_seed s WHERE s.discipline_code=d.code
    ) t
), updated_at=timezone('UTC',now())
WHERE d.code IN ('SAT_MATH','SAT_RW');
